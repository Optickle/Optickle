% sCon = convertSimulink(opt, sys, f)
%
% Converts a simulink model to a Optickle control struct.
% If f is given in Hz, the simulink model is assumed to be in Hz.
% 
% Simulink inputs and outputs are identified with Optickle
% probes and drives by their names.  A name which starts with
% "probe:" is matched with a probe.  A name which starts with
% "drive:" is matched with a drive.  If an optic has multiple
% drive types, the drive type can be appended after a "."
% (e.g., "drive:Mod1.phase").
%
% The matching of Optickle's probe outputs to Simulink inputs,
% and Optickle drive inputs to Simulink outputs forms the core
% of this operation.  To help with the simulation of oscillator
% phase noise, probes can be used as Optickle input (Simulink
% outputs) which transfer oscillator phase to probe output.
% In this case the prefix "phase:" is used.
%
% Though a bit more obscure, the drives are also matched to
% Simulink inputs, such that they may be used to form loops in
% Simulink (e.g., optic positions can be used to construct
% local sensors, with the mechanical transfer functions modified
% by radiation pressure, as in mMech from tickle).  In this case
% the prefix "sense:" is used.
%
% The control struct contains the following fields:
%
%  f - frequency vector (suplied by user)
%  Nin - control system inputs
%  Nout - control system outputs
%  mCon - control matrix for each frequency Nin x Nout x Naf
%  mPrbIn - probe output to control system input map (Nin x Nprobe)
%  mDrvIn - drive output to control system input map (Nin x Ndrive)
%  mPrbOut - control system output to probe input map (Nprobe x  Nout)
%  mDrvOut - control system output to drive input map (Ndrive x  Nout)
%
%  SystemName - system name (suplied by user)
%  InputName - input names, from linmod
%  OutputName - output names, from linmod

function sCon = convertSimulink(opt, sys, f)

  % sizes of things
  Ndrv = opt.Ndrive;
  Nprb = opt.Nprobe;

  % get linmod struct and control matrix
  sWarn = warning('off', 'Simulink:SL_UsingDefaultMaxStepSize');
  slin = linmod(sys);
  warning(sWarn.state, sWarn.identifier);

  mCon = freqresp(ss(slin.a, slin.b, slin.c, slin.d), f);
  Nin = length(slin.InputName);
  Nout = length(slin.OutputName);
  
  % match inputs to probes (and drives)
  mPrbIn = sparse(Nin, Nprb);
  mDrvIn = sparse(Nin, Ndrv);
  for n = 1:Nin
    mPrbIn(n, getSimProbeIndex(opt, slin.InputName{n}, 'probe:')) = 1;
    mDrvIn(n, getSimDriveIndex(opt, slin.InputName{n}, 'sense:')) = 1;
  end
  
  % match outputs to drives (and probes)
  mPrbOut = sparse(Nprb, Nout);
  mDrvOut = sparse(Ndrv, Nout);
  for n = 1:Nout
    mPrbOut(getSimProbeIndex(opt, slin.OutputName{n}, 'phase:'), n) = 1;
    mDrvOut(getSimDriveIndex(opt, slin.OutputName{n}, 'drive:'), n) = 1;
  end
    
  % make control struct
  sCon.f = f;
  sCon.Nin = Nin;
  sCon.Nout = Nout;
  sCon.mCon = mCon;
  sCon.mPrbIn = mPrbIn;
  sCon.mDrvIn = mDrvIn;
  sCon.mPrbOut = mPrbOut;
  sCon.mDrvOut = mDrvOut;

  sCon.SystemName = sys;
  sCon.InputName = slin.InputName;
  sCon.OutputName = slin.OutputName;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function m = getSimProbeIndex(opt, name, prefix)

  % remove system name
  nSep = strfind(name, '/');
  if ~isempty(nSep)
    name = name(nSep(end) + 1:end);
  end
  
  % look for probe names
  Npre = length(prefix);
  if strncmp(name, prefix, Npre)
    m = getProbeNum(opt, name(Npre + 1:end));
  else
    m = [];
  end
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function m = getSimDriveIndex(opt, name, prefix)

  % remove system name
  nSep = strfind(name, '/');
  if ~isempty(nSep)
    name = name(nSep(end) + 1:end);
  end
  
  % look for drive names
  Npre = length(prefix);
  if strncmp(name, prefix, Npre)
    name = name(Npre + 1:end);
    nSep = strfind(name, '.');
    if length(nSep) == 1
      m = getDriveIndex(opt, name(1:nSep - 1), name(nSep + 1:end));
    else
      m = getDriveIndex(opt, name);
    end
  else
    m = [];
  end
