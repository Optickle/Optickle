% Compute DC fields, and DC signals, and AC transfer functions
%
% NOTE: for separate optical response and opto-mechanics, see tickle2
%
% [fDC, sigDC, sigAC, mMech, noiseAC, noiseMech] = tickle(opt, pos, f, nDrive)
% opt       - Optickle model
% pos       - optic positions (Ndrive x 1, or empty)
% f         - audio frequency vector (Naf x 1)
%
% fDC       - DC fields at this position (Nlink x Nrf)
%             where Nlink is the number of links, and Nrf
%             is the number of RF frequency components.
% sigDC     - DC signals for each probe (Nprobe x 1)
%             where Nprobe is the number of probes.
% sigAC     - transfer matrix (Nprobe x Ndrive x Naf),
%             where Ndrive is the total number of optic drive
%             inputs (e.g., 1 for a mirror, 2 for a RFmodulator).
%             Thus, sigAC is arranged such that sigAC(n, m, :)
%             is the TF from the drive m to probe n.
%             NOTE: sigAC includes both optics and opto-mechanics.
%               See tickle2 if you want them separately. 
% mMech     - opto-mechanical modification of the inputs (Nin x Nin x Naf)
%             if there are no opto-mechanics, this will be the identity.
%             NOTE: mMech does NOT include the mechanical response to
%               force (i.e., MechTF).
% noiseAC   - quantum noise at each probe (Nprb x Naf)
% noiseMech - quantum noise at each drive (Ndrv x Naf)
%
% UNITS:
% Assuming the input laser power is in Watts, and laser wavelength is in
% meters, the outputs are generically 
% fDC   - [sqrt(W)]
% sigDC - [W]
% sigAC - [W/m]
% assuming the drive is a mirror. If the drive is a modulator, then sigAC
% is [W/AM] or [W/rad] for an amplitude or phase modulation, respectively.
%
% EXAMPLE:
% f = logspace(0, 3, 300);
% opt = optFP;
% [fDC, sigDC, sigAC, mMech] = tickle(opt, [], f);
%
% (see also tickle2, @Optickle/Optickle)


function varargout = tickle(opt, varargin)

  
  % decide which calculation is necessary
  isAC = nargout > 2;
  isNoise = nargout > 4;

  % call tickle2
  if ~isAC
    [fDC, sigDC] = tickle2(opt, varargin{:});
  else
    if ~isNoise
      [fDC, sigDC, mInOut, mMech] = tickle2(opt, varargin{:});
    else
      [fDC, sigDC, mInOut, mMech, noiseOpt, noiseMech] = ...
        tickle2(opt, varargin{:});
    end
    sigAC = getProdTF(mInOut, mMech);
  end
  
  % assign the outputs
  varargout{1} = fDC;
  varargout{2} = sigDC;

  if isAC
    varargout{3} = sigAC;
    varargout{4} = mMech;
  end
  
  if isNoise
    varargout{5} = noiseOpt;
    varargout{6} = noiseMech;
  end
end
