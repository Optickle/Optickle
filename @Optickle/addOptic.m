% Add a general optic to the model.
%
% [opt, sn] = addOptic(opt, obj)
%
% This function is generally not used directly.  Use the add functions
% for specific types of optics instead (e.g., addMirror).
%
% see also addBeamSplitter, addMirror, addModulator, addSink, addSource, etc.

function [opt, sn] = addOptic(opt, obj)

  % increment optic serial number
  sn = opt.Noptic + 1;
  opt.Noptic = sn;

  % add optic with new serial number and drive indices
  opt.optic{sn, 1} = setSN(obj, sn, opt.Ndrive);

  % update drive counter
  opt.Ndrive = opt.Ndrive + obj.Ndrive;
