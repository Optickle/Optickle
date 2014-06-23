function showfDC(opt, fDC)
% SHOWFDC  Pretty-print the fDC matrix returned by Optickle
%
% Example:
%
% >> opt = optFP;
% >> f = logspace(log10(0.1), log10(7000), 101);
% >> [fDC, sigDC, sigAC] = tickle(opt, [], f);
% >> showfDC(opt, fDC)
%                                    | -20 MHz    DC     +20 MHz  
% -----------------------------------+------------------------------
%              Laser->out --> AM<-in |   0  W   100  W     0  W   
%                 AM->out --> PM<-in |   0  W   100  W     0 pW   
%               PM->out --> Mod1<-in |   0  W   100  W     0 pW   
%               Mod1->out --> IX<-bk | 990 mW    98  W   990 mW   
%                  IX->fr --> EX<-fr |  12 mW    12 kW    12 mW   
%                  EX->fr --> IX<-fr |  12 mW    12 kW    12 mW   
%                IX->bk --> REFL<-in | 990 mW    86  W   990 mW   
% TRANS_TELE->out --> TRANS_SMIR<-fr |  12 uW    12  W    12 uW   
%      TRANS_SMIR->fr --> TRANSa<-in |   6 uW     6  W     6 uW   
%      TRANS_SMIR->bk --> TRANSb<-in |   6 uW     6  W     6 uW   
%          EX->bk --> TRANS_TELE<-in |  12 uW    12  W    12 uW   
%   FlashLight->out --> FakeTele<-in |   0  W     0  W     1 pW   
%           FakeTele->out --> EX<-bk |   0  W     0  W     1 pW  
%
% Note that the field phases are ignored; the values shown are the
% modulus squared of the field amplitudes.
%
% See also SHOWSIGDC

% Tobin Fricke <tobin.fricke@ligo.org> July 2011
    
vFrf = get(opt, 'vFrf');

% minimal sanity check
if ~isequal(size(fDC), [opt.Nlink length(vFrf)])
    error('This opt and sigDC don''t seem to go together');
end

% format the link labels
labels = cellfun(...
    @(link) sprintf('%s --> %s', ...
                    getSourceName(opt, link), getSinkName(opt, link)), ...
    num2cell(1:opt.Nlink), 'UniformOutput', 0);

% how long is the longest label?
max_label_len = max(cellfun(@length, labels));

% how long do we want them to be?
label_len = max_label_len;

label_fmtstr = sprintf('%% %ds | ', label_len);

% print out the banner of frequency labels
fprintf(label_fmtstr,'');
for jj=1:length(vFrf)
    if vFrf(jj)==0
        fprintf('  DC     ');
    else
        [prefix, value] = metricize(vFrf(jj));
        if abs(value) < 10
            precision = 1;
        else
            precision = 0;
        end
        fprintf('%+3.*f %sHz  ',precision, value, prefix);
    end
end

% print out the "---+--------" line
fprintf('\n%s\n', [ repmat('-', 1, label_len + 1) '+' ...
    repmat('-', 1, 10*length(vFrf))]);

% define a minumum power value for printing
smallPower = 1e-10 * max(abs(fDC(:))).^2;
minPower = 1e-10 * smallPower;
  
% print out the data for each link
for ii=1:opt.Nlink,
    label = labels{ii};
    % if the label is too long, truncate it
    if length(label) > label_len
        label = label((end-label_len+1):end);
    end
    % print out the link label
    fprintf(label_fmtstr, label);
    % print out the field amplitudes
    for jj=1:length(vFrf),
        amp = abs(fDC(ii,jj))^2;
        [prefix, value] = metricize(amp);
        if value < 10
            precision = 1;  % 3.1  (one decimal)
        else
            precision = 0;  % 137  (no decimals)
        end
        if amp < minPower
           fprintf('---  W   ');
        elseif amp < smallPower
           fprintf('e%d W   ', round(log10(amp)));
        else
           fprintf('%3.*f %sW   ', precision, value, prefix);
        end
    end
    fprintf('\n');
end
end


function [prefix, val] = metricize(val)

if val < 0
    lf = log10(-val);
else
    lf = log10(val);
end

if lf > 9
    prefix = 'G';
    val = val / 1e9;
elseif lf > 6
    prefix = 'M';
    val = val / 1e6;
elseif lf > 3
    prefix = 'k';
    val = val / 1000;
elseif (lf > 0) || (lf == -inf)
    prefix = ' ';
elseif lf > -3
    prefix = 'm';
    val = val * 1000;
elseif lf > -6
    prefix = 'u';    % 'μ' works on linux 
    val = val * 1e6;
elseif lf > -9
    prefix = 'n';
    val = val * 1e9;
else
    prefix = 'p';
    val = val * 1e12;
end
end
