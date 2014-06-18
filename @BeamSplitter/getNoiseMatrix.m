% mQuant = getNoiseMatrix(obj, pos, par)
%   mQuant is (Nrf * Nout) x Nnoise
%
% returns a matrix of noise vectors which correspond to
% the quantum noises which enter the Optickle system.
%
% The BeamSplitter is a combination of 2 mirrors, so it has
% up to 14 internal loss points.  See @Mirror/getNoiseMatrix.

function mQuant = getNoiseMatrix(obj, pos, par)
  
  % mapping matrices
  [~, ~, mOutArf, mOutBrf] = BeamSplitter.getMirrorIO(2 * par.Nrf);

  % get mirror noise matrix
  mQuantMir = obj.mir.getNoiseMatrix(pos, par);
  
  % build BS noise
  mQuant = [mOutArf * mQuantMir, mOutBrf * mQuantMir];
end