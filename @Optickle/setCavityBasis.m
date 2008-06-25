% opt = setCavityBasis(opt, name1, name2)
%
% Sets the basis as determined by the two mirrors
% (specified by name1 and name2).  The two mirrors must
% make a simple 2 mirror cavity, connected front-to-front.
%
% The modal basis used for tickle01 can be set at the
% field source (see addSource).  Or with setCavityBasis.
%
% Example (from optFP):
% opt = setCavityBasis(opt, 'IX', 'EX');

function opt = setCavityBasis(opt, name1, name2)

  sn1 = getSerialNum(opt, name1);
  sn2 = getSerialNum(opt, name2);
  
  obj1 = opt.optic{sn1};
  obj2 = opt.optic{sn2};
  
  % make sure this is a simple cavity
  if ~isa(obj1, 'Mirror') || ~isa(obj2, 'Mirror')
    error('Cavity elements must be mirrors')
  elseif obj1.out(1) ~= obj2.in(1) || obj2.out(1) ~= obj1.in(1)
    error('Cavity elements must be connected front-to-front')
  end
  
  lnk1 = opt.link(obj1.in(1));
  lnk2 = opt.link(obj2.in(1));
  len = (lnk1.len + lnk2.len) / 2;
  dl = (lnk1.len - lnk2.len) / 2;
  if abs(dl / len) > 1e-6
    error('Cavity internal link lengths do not match.')
  end
  
  % set bases (do both in case one has Chr == 0)
  [z0, z1, z2] = cavHG(len, 1 / obj1.Chr, 1 / obj2.Chr);
  opt.optic{sn1} = setFrontBasis(obj1, -z1);
  opt.optic{sn2} = setFrontBasis(obj2,  z2);
  