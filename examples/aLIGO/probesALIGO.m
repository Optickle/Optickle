%---------------- probesFullIFO.m -------------
% Adds probes on an interferomter model
%
%  modified by Kiwamu Izumi (July 20th 2011)
%  modified for Optickle 2 by mevans (14 July 2014)
%
%--------------------------------------------------------
%
%[Description]
%   This function adds the neccessary RFPDs and DCPDs on
%  an interferomter model.  These probes are for length sensing.
%
% Example usage : 
%              par = paramALIGO(10);  % argument is input power
%              opt = optALIGO(par);
%              opt = probesALIGO(opt, par);
%--------------------------------------------------------
%


function opt = probesALIGO(opt, par)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Add attenuators and terminal sinks
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % 3rd addSink argument is power loss, default is 1
  % Attenuator set to match what is there in the real IFOs, maybe.
  % AS: transmission to the dark port from SR, before the OMC
  
  
  % 'Att' stands for 'Attenuation'
  opt.addSink('AttREFL', 0.95);
  opt.addSink('AttAS',   0);
  opt.addSink('AttPOP',  0.75);
  opt.addSink('AttPOX',  0);
  opt.addSink('AttPOY',  0);
  
  % these sinks define field evaluation points for probes at each port
  opt.addSink('REFL');
  opt.addSink('AS');
  opt.addSink('OMC');
  opt.addSink('POP');
  opt.addSink('POX');
  opt.addSink('POY');
  opt.addSink('TRX');
  opt.addSink('TRY');
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Add Links
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % REFL
  opt.addLink('PR', 'bk', 'AttREFL', 'in', 0);
  opt.addLink('AttREFL', 'out', 'REFL', 'in', 0);
  
  % AS Asymmetric port
  opt.addLink('PO_AS', 'fr', 'AttAS', 'in', 0);
  opt.addLink('AttAS', 'out', 'AS', 'in', 0);
  
  % OMC Transmission
  opt.addLink('OMCb', 'bk', 'OMC', 'in', 0);
  
  % POP
  opt.addLink('PR2', 'bkB', 'AttPOP', 'in', 0);
  opt.addLink('AttPOP', 'out', 'POP', 'in', 0);  
  
  % POX
  opt.addLink('IX', 'po', 'AttPOX', 'in', 0);
  opt.addLink('AttPOX', 'out', 'POX', 'in', 0);
  
  % POY
  opt.addLink('IY', 'po', 'AttPOY', 'in', 0);
  opt.addLink('AttPOY', 'out', 'POY', 'in', 0);  

  % TRX and TRY
  opt.addLink('EX', 'bk', 'TRX', 'in', 5);
  opt.addLink('EY', 'bk', 'TRY', 'in', 5);  
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Add Probes
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % demodulation frequencies
  f1 = par.Mod.f1;
  f2 = par.Mod.f2;
  fM = abs(f2 - f1);  % sideband difference frequency
  fP = f2 + f1;       % sideband sum frequency
  
  % demod phases
  phi = par.phi;
  
  % REFL signals (reflected or symmetric port, with 3f signals)
  opt.addReadout('REFL',  [f1, phi.phREFL1; f2, phi.phREFL2]);
  opt.addProbeIn('REFL_3I1', 'REFL', 'in', 3 * f1, phi.phREFL31);         % 3f1 demod I
  opt.addProbeIn('REFL_3Q1', 'REFL', 'in', 3 * f1, phi.phREFL31 + 90);    % 3f1 demod Q
  opt.addProbeIn('REFL_3I2', 'REFL', 'in', 3 * f2, phi.phREFL32);         % 3f2 demod I
  opt.addProbeIn('REFL_3Q2', 'REFL', 'in', 3 * f2, phi.phREFL32 + 90);    % 3f2 demod Q
  
  % AS signals (anti-symmetric port before the OMC)
  opt.addReadout('AS',  [f1, phi.phAS1; f2, phi.phAS2]);
  
  % POP signals (PR2 transmission)
  opt.addReadout('POP',  [f1, phi.phPOP1; f2, phi.phPOP2]);
  
  % OMC transmission (just DC)
  opt.addProbeIn('OMC DC', 'OMC', 'in',  0, 0);
  
  % Arm Transmitted DC signals
  opt.addProbeIn('TRX_DC', 'TRX', 'in', 0, 0);
  opt.addProbeIn('TRY_DC', 'TRY', 'in', 0, 0);

end
