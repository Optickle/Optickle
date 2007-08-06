% mNP = getNoisePower(Thr, Lhr, Rar, Lmd, in, out)
%
% This function returns the quantum noise power matrix for
% a mirror.  It is not in the Mirror class, because it is
% also used by BeamSplitter.  There is probably a better solution.

function mNP = getNoisePower(Thr, Lhr, Rar, Lmd, in, minQuant)
  
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
  
  % derived Rs and Ts
  Rhr = 1 - Thr - Lhr;
  Tar = 1 - Rar;
  Tmd = 1 - Lmd;

  % composite Ts
  Tfb = Tmd * Rhr * Tmd;
  Tpo = Tar * Tfb;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Build noise power matrix
  mNP = zeros(4, 0);

  if Lhr ~= 0
    % loss at HR surface, front and back side
    mNP1 = zeros(4, 2);
    mNP1(1, 1) = Lhr;
    mNP1(:, 2) = [0; Tar * Tmd; 0; Tpo * Rar * Tmd] * Lhr;
    mNP = [mNP, mNP1];
  end
  
  if Lmd ~= 0
    % loss in medium, from back to front and front to back
    mNP1 = zeros(4, 2);
    mNP1(:, 1) = [Thr; Tar * Tmd * Rhr; 0; Tpo * Rar * Tmd * Rhr] * Lmd;
    mNP1(:, 2) = [0; Tar; 0; Tpo * Rar] * Lmd;
    mNP = [mNP, mNP1];
  end
  
  if Rar ~= 0
    % N1 - vacuum input on back of PI (back input pick-off)
    % N2 - vacuum input on back of BK (back output)
    % N3 - vacuum and losses leading to PO (back output pick-off)
    mNP1 = zeros(4, 3);
    mNP1(:, 1) = [Thr * Tmd * Rar; Tar * Tfb * Rar; Tar;
                 Tpo * Rar * Tfb * Rar];
    mNP1(:, 2) = [0; Rar; 0; Tpo * Tar];
    mNP1(4, 3) = Rar + Tar * (Lmd + Tmd * (Lhr + Thr + Rhr * Lmd));
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
    mNP1 = [Rhr; Tar * Tmd * Thr; 0; Tpo * Rar * Tmd * Thr];
    mNP = [mNP, mNP1];
  end
  
  if in(2) == 0
    mNP1 = [Thr * Tmd * Tar; Tar * Tfb * Tar; Rar;
               Tpo * Rar * Tfb * Tar];
    mNP = [mNP, mNP1];
  end
  
