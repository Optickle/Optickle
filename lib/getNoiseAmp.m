% mNP = getNoiseAmp(Thr, Lhr, Rar, Lmd, in, out)
%
% This function returns the quantum noise power matrix for
% a mirror.  It is not in the Mirror class, because it is
% also used by BeamSplitter.  There is probably a better solution.

function mNP = getNoiseAmp(Thr, Lhr, Rar, Lmd, phi, in, minQuant)
  
  % zero small losses
  if Lhr < minQuant
    Lhr = 0;
  end
  if Lmd < minQuant
    Lmd = 0;
  end
  if Rar < minQuant
    Rar = 0;
  end
  
  % ==== From getFieldMatrix
  % reflection phases
  frp = exp(1i * phi);
  brp = conj(frp);
  
  % amplitude reflectivities, transmissivities and phases
  hr = -sqrt(1 - Thr - Lhr);			% HR refl
  ht =  sqrt(Thr);				% HR trans
  ar = -sqrt(Rar);				% AR refl
  at =  sqrt(1 - Rar);				% AR trans
  bt =  sqrt(1 - Lmd);				% bulk trans

  hrf =  hr * frp;
  hrb = -hr * brp;
  arf =  ar * frp;
  arb = -ar * brp;
  
  % transmission combinations
  hrbt = hrb * bt;
  arbt = arb * bt;
  htbt =  ht * bt;
  atbt =  at * bt;
  tbo = atbt * hrbt;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Build noise power matrix
  mNP = zeros(4, 0);

  if Lhr ~= 0
    % loss at HR surface, front and back side
    mNP1 = zeros(4, 2);
    aNoise = sqrt(Lhr);
    mNP1(1, 1) = aNoise;
    mNP1(:, 2) = [0; atbt; 0; tbo * arbt] * aNoise;
    mNP = [mNP, mNP1];
  end
  
  if Lmd ~= 0
    % loss in medium, from back to front and front to back
    mNP1 = zeros(4, 2);
    aNoise = sqrt(Lmd);
    mNP1(:, 1) = [ht; atbt * hrb; 0; tbo * arbt * hrb] * aNoise;
    mNP1(:, 2) = [0; at; 0; tbo * arb] * aNoise;
    mNP = [mNP, mNP1];
  end
  
  if Rar ~= 0
    % N1 - vacuum input on back of PI (back input pick-off)
    % N2 - vacuum input on back of BK (back output)
    % N3 - vacuum and losses leading to PO (back output pick-off)
    mNP1 = zeros(4, 3);
    mNP1(:, 1) = [htbt * arb; tbo * arb; at;
                 tbo * arbt * hrbt * arb];
    mNP1(:, 2) = [0; arb; 0; tbo * at];

    % this one is a bit messy...
    Rhr = 1 - Thr - Lhr;
    Tar = 1 - Rar;
    Tmd = 1 - Lmd;
    
    mNP1(4, 3) = sqrt(Rar + Tar * (Lmd + Tmd * (Lhr + Thr + Rhr * Lmd)));
    mNP = [mNP, mNP1];
  else
    % N1 - vacuum for PI
    % N2 - vacuum for PO
    mNP1 = [0; 0; 1; 0];
    mNP2 = [0; 0; 0; 1];
    mNP = [mNP, mNP1, mNP2];
  end
  
  % add power from open inputs
  if in(1) == 0
    mNP1 = [hrf; atbt * ht; 0; tbo * arbt * ht];
    mNP = [mNP, mNP1];
  end
  
  if in(2) == 0
    mNP1 = [htbt * at; tbo * at; arf; tbo * arbt * hrbt * at];
    mNP = [mNP, mNP1];
  end
