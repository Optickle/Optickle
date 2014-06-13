% opt = addPolWavelength(opt, name, linkIn, portIn)
%   add a generic readout for different polarizations/wavelengths
% 
% This function adds a collection of probes for different polarizations / 
% wavelengths at a given location.
%
% name   - sink name (also used as base name for probes in the readout)
%          The output are the two sinks at different guoy phases
% linkIn - name of input optic
% portIn - name of port on input optic (default is 'out')


function opt = addPolWavelength(opt, name, linkIn, portIn)

  llamb = unique(opt.lambda);  % list of wavelengths

  if nargin < 4
    portIn = 'out';
  end
  
  % split by polarization
  nameSplitPol = sprintf('%s%s', name, 'SplitPol');
  mPBS = [];
  for kk=1:size(llamb,1)
    mPBS = [mPBS;1 llamb(kk) 1;0 llamb(kk) 0];
  end
  opt = addMirror(opt, nameSplitPol, 45, 0, mPBS);
  opt = addLink(opt, linkIn, portIn, nameSplitPol, 'fr', 0);
  
  % split by wavelength
  for kk=1:size(llamb,1)
    mDich = [];
    for jj=1:size(llamb,1)
      if llamb(kk) == llamb(jj)
        mDich = [mDich;1 llamb(jj)];
      else
        mDich = [mDich;0 llamb(jj)];
      end
    end
    nameSplit = sprintf('%s%s%d', name, 'SplitP', round(llamb(kk)/1e-9));
    opt = addMirror(opt, nameSplit, 45, 0, mDich);
    nameSplit = sprintf('%s%s%d', name, 'SplitS', round(llamb(kk)/1e-9));
    opt = addMirror(opt, nameSplit, 45, 0, mDich);
    
  end
  
  nameSplit = sprintf('%s%s%d', name, 'SplitP', round(llamb(1)/1e-9));
  opt = addLink(opt, nameSplitPol, 'fr', nameSplit, 'fr', 0);
  nameSplit = sprintf('%s%s%d', name, 'SplitS', round(llamb(1)/1e-9));
  opt = addLink(opt, nameSplitPol, 'bk', nameSplit, 'fr', 0);
  for kk=2:size(llamb,1)
    for ps=['P','S']
      nameSplitIn = sprintf('%s%s%s%d', name, 'Split', ps, round(llamb(kk-1)/1e-9));
      nameSplitOut = sprintf('%s%s%s%d', name, 'Split', ps, round(llamb(kk)/1e-9));
      nameSink = sprintf('%s%s%d', name, ps, llamb(kk-1)/1e-9);
      opt = addLink(opt, nameSplitIn, 'fr', nameSplitOut, 'fr', 0);
      opt = addSink(opt, nameSink);
      opt = addLink(opt, nameSplitIn, 'bk', nameSink, 'in', 0);
      opt = addProbeIn(opt, [nameSink,'_DC'], nameSink, 'in', 0, 0);
    end
  end
  for ps=['P','S']
    nameSink = sprintf('%s%s%d', name, ps, round(llamb(end)/1e-9));
    nameSplitIn = sprintf('%s%s%s%d', name, 'Split', ps, round(llamb(kk)/1e-9));
    opt = addSink(opt, nameSink);
    opt = addLink(opt, nameSplitIn, 'bk', nameSink, 'in', 0);
    opt = addProbeIn(opt, [nameSink,'_DC'], nameSink, 'in', 0, 0);
  end
  
  
  
