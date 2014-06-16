% testDetuneFP
% this function tests the output of tickle for detuned FP cavity
%

function outstruct = testDetuneFP()

    % create the model
    opt = testOptFP;

    % get some drive indexes
    nEX = getDriveIndex(opt, 'EX');

    % compute the DC signals and TFs on resonance
    f = logspace(-1, 3, 200)';
    [fDC0, sigDC0, sigAC0, mMech0, noiseAC0] = tickle(opt, [], f);

    % compute the same a little off resonance
    pos = zeros(opt.Ndrive, 1);
    pos(nEX) = 0.1e-9;
    [fDC1, sigDC1, sigAC1, mMech1, noiseAC1] = tickle(opt, pos, f);

    % and a lot off resonance
    pos(nEX) = 1e-9;
    [fDC2, sigDC2, sigAC2, mMech2, noiseAC2] = tickle(opt, pos, f);

    outstruct = var2struct(f,fDC0,fDC1,fDC2,sigDC0,sigDC1,sigDC2,...
                           sigAC0,sigAC1,sigAC2,mMech0,mMech1,mMech2,...
                           noiseAC0,noiseAC1,noiseAC2);
end