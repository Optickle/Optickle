% sCon = convertSimulink(opt, sys, f)
%
% ===> DO NOT USE THIS FUNCTION <===
% This is only here for testing and may be removed in a future
% version of Optickle.
%
% Converts a simulink model to a Optickle control struct.
% If f is given in Hz, the simulink model is assumed to be in Hz.
% 
% The matching of Optickle's probe outputs to Simulink inputs,
% and Optickle drive inputs to Simulink outputs forms the core
% of this operation.  Simulink inputs and outputs are identified
% with Optickle probes and drives by their names.  An input name
% which starts with "probe:" is matched with a probe.  An output
% name which starts with "drive:" is matched with a drive.  If an
% optic has multiple drive types, the drive type can be appended
% after a "." (e.g., "drive:Mod1.phase").  The results of this
% matching are the mPrbIn and mDrvOut matrices.
%
% To help with the simulation of oscillator phase noise, probes
% can be used as Optickle input (Simulink outputs) which transfer
% oscillator phase to probe output. In this case the prefix "phase:"
% is used, and the result is the mPrbOut matrix.
%
% Though a bit more obscure, the drives are also matched to
% Simulink inputs, such that they may be used to form loops in
% Simulink (e.g., optic positions can be used to construct
% local sensors, with the mechanical transfer functions modified
% by radiation pressure, as in mMech from tickle).  Here the
% prefix "sense:" is used, and the result is the mDrvIn matrix.
%
% The control struct contains the following fields:
%
%  f - frequency vector (Naf x 1, supplied by user)
%  Nin - control system inputs
%  Nout - control system outputs
%  mCon - control matrix for each f value (Nin x Nout x Naf, from freqresp)
%  mPrbIn - probe output to control system input map (Nin x Nprobe)
%  mDrvIn - drive output to control system input map (Nin x Ndrive)
%  mPrbOut - control system output to probe input map (Nprobe x  Nout)
%  mDrvOut - control system output to drive input map (Ndrive x  Nout)
%
%  SystemName - system name (supplied by user)
%  InputName - input names, from linmod
%  OutputName - output names, from linmod

function sCon = convertSimulink(opt, sys, f, addAll)

  % sizes of things
  Ndrv = opt.Ndrive;
  Nprb = opt.Nprobe;

  % make sure Optickle IO comes last
  load_system(sys);
  blks = find_system(sys, 'BlockType', 'Inport');
  Nblks = length(blks);
  NinOpt = 0;
  for n = 1:Nblks
    name = remSysName(blks{n});
    if strncmp('probe:', name, 6) || strncmp('sense:', name, 6)
      set_param(blks{n}, 'Port', int2str(Nblks))
    end
    NinOpt = NinOpt + 1;
  end

  blks = find_system(sys, 'BlockType', 'Outport');
  Nblks = length(blks);
  NoutOpt = 0;
  for n = 1:Nblks
    name = remSysName(blks{n});
    if strncmp('drive:', name, 6) || strncmp('phase:', name, 6)
      set_param(blks{n}, 'Port', int2str(Nblks))
    end
    NoutOpt = NoutOpt + 1;
  end

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
    
  %%%%% if requested, add other inputs and outputs
  if nargin > 4 && addAll
    
  end
  
  %%%%% make control struct
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
function name = remSysName(name)

  % remove system name
  nSep = strfind(name, '/');
  if ~isempty(nSep)
    name = name(nSep(end) + 1:end);
  end
  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function m = getSimProbeIndex(opt, name, prefix)

  % remove system name
  name = remSysName(name);
  
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
  name = remSysName(name);
  
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
