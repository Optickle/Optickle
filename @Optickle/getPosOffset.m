% get the position of optic's drive or drives
% 
% pos = getPosOffset(opt, name)
% name - name or serial number of an optic

function pos = getPosOffset(opt, name)

  sn = getSerialNum(opt, name);
  pos = getPosOffset(opt.optic{sn});
