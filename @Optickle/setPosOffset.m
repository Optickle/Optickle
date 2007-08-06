% set the position offset of optic's drive or drives
% 
% opt = setPosOffset(opt, name, pos)
% snOpt - name or serial number of an optic
% pos - zero position for this optic

function opt = setPosOffset(opt, name, pos)

  sn = getSerialNum(opt, name);
  opt.optic{sn} = setPosOffset(opt.optic{sn}, pos);
