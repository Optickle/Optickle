% vBasis = getAllFieldBases(opt)
%
% Return field basis vector, one basis for each field evaluation
% point (FEP).  The bases are determined based on propagation of
% user set bases (see @Optic/setFieldBasis).
%
% The "basis vector" is a Nfldx2 matrix of complex numbers.
% The vector vBasis(:, 1) contains the x-axis bases.
% The vector vBasis(:, 2) contains the y-axis bases.
%   see also @OpHG/apply
%
% Example, Gouy phase of each propagation step:
% opt = optFP;
% vDist = getLinkLengths(opt);
% vBasis = getAllFieldBases(opt);
% vPhiGouy = getGouyPhase(vDist, vBasis(:, 2)) * 180 / pi

function vBasis = getAllFieldBases(opt)

  % construct default basis
  Nopt = opt.Noptic;
  Nfld = opt.Nlink;
  vBasis = zeros(Nfld, 2);

  isSet = false(Nfld, 1);  % basis already determined
  isNew = false(Nfld, 1);  % basis newly determined... propagate!
  
  % look for mirrors with specified waist distances
  % or sources with specified output bases
  % and specify them as "new" for next loop
  for n = 1:Nopt
    obj = opt.optic{n};
    if isa(obj, 'Mirror')
      qxy = getFrontBasis(obj);
      if ~isempty(qxy)
	% front input basis is specified for this mirror
	vBasis(obj.in(1), :) = qxy;
	isNew(obj.in(1)) = true;
	isSet(obj.in(1)) = true;
      end
    end
    if isa(obj, 'Source') && obj.out ~= 0
      qxy = obj.qxy;
      nOut = obj.out;
      dProp = opt.link(nOut).len;
      if ~isempty(qxy)
	% front input basis is specified for this mirror
	vBasis(nOut, :) = apply(shift(OpHG, dProp), qxy);
	isNew(nOut) = true;
	isSet(nOut) = true;
      end
    end
  end
  
  % loop through the basis vector
  % passing new bases from inputs to outputs
  % and reporting inconsitencies
  while any(isNew)
    nNew = find(isNew);
    for nn = 1:length(nNew)
      n = nNew(nn);
      isNew(n) = false;

      lnk = opt.link(n);
      qIn = vBasis(n, :);           % basis at end of link

      %%%%%%%%%%%%%%%% propagate forward through link sink
      snSink = lnk.snSink;
      portSink = lnk.portSink;
      obj = opt.optic{snSink};
	
      % compute output bases
      qm = getBasisMatrix(obj);  % get basis transfor matrix
      for m = 1:obj.Nout
	nOut = obj.out(m);
	if nOut == 0 || ~isValid(qm(m, portSink))
	  % not connected
	  continue
	end
	
	dProp = opt.link(nOut).len;
	qOp = shift(qm(m, portSink), dProp); % operator with shift
	qOut = apply(qOp, qIn);             % basis at end of output link
	if ~isSet(nOut)
	  % basis not specified, assign this one
	  vBasis(nOut, :) = qOut;
	  isNew(nOut) = true;
	  isSet(nOut) = true;
	  %disp(sprintf('Set %d from %d (forward).', nOut, n));
	else
	  checkConsistency(vBasis(nOut, :), qOut, n, nOut, opt);
	end
      end
      
      %%%%%%%%%%%%%%%% propagate backward through link source
      snSource = lnk.snSource;
      portSource = lnk.portSource;
      obj = opt.optic{snSource};
	
      % compute input bases
      qm = getBasisMatrix(obj);  % get basis transfer matrix
      for m = 1:obj.Nin
	nOut = obj.in(m);
	if nOut == 0 || ~isValid(qm(portSource, m))
	  % not connected
	  continue
	end
	
	qOp = shift(qm(portSource, m), lnk.len); % operator with shift
	qOut = apply(inv(qOp), qIn);
	if ~isSet(nOut)
	  % basis not specified, assign this one
	  vBasis(nOut, :) = qOut;
	  isNew(nOut) = true;
	  isSet(nOut) = true;
	  %disp(sprintf('Set %d from %d (backward).', nOut, n));
    else
      %fprintf('Parameters %g, %g, %g, %g\n ', vBasis(nOut, 1), qOut, n, nOut);
      checkConsistency(vBasis(nOut, :), qOut, n, nOut, opt);

	end
      end
    end
  end
    
  % check for fields with unspecified bases
  if any(~isSet)
    for n = find(~isSet)
      fprintf(1, 'Basis not found for field %d\n', n);
    end
    error('Some fields have no basis!  see @Mirror/setFrontBasis')
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function b = checkConsistency(q1, q2, n, nOut, opt)

  qc = abs(q1 + q2);
  qd = abs(q1 - q2);
  %err = max(qd ./ qc);
  %Use only Y basis (Optickle does TEM 10)
  err = qd(2) / qc(2);
  if err > 5e-3
    warning('Consistency check failed for field %d from %d (err = %g)!', ...
      nOut, n, err);
    sourceOut = getSourceName(opt, nOut);
    sinkOut =  getSinkName(opt, nOut);
    sourceIn = getSourceName(opt, n);
    sinkIn =  getSinkName(opt, n);
    disp(sprintf('q1 is the basis for field %d (from %s to %s): the distance past the waist is %g m, the Rayleigh range is %g m' , ...
      n, sourceIn, sinkIn, real(q1(2)), -imag(q1(2))));
    disp(sprintf('q2 is the basis for field %d (from %s to %s): the distance past the waist is %g m, the Rayleigh range is %g m' , ...
      nOut, sourceOut, sinkOut, real(q2(2)), -imag(q2(2))));
  end
end
