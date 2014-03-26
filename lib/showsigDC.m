function showsigDC(opt, sigDC)
% SHOWSIGDC  Pretty-print the sigDC matrix returned by Optickle
%
% Example:
%
% >> opt = optFP;
% >> f = logspace(log10(0.1), log10(7000), 101);
% >> [fDC, sigDC, sigAC] = tickle(opt, [], f);
% >> showsigDC(opt, sigDC)
% 
%     probe | power
% ----------+---------
%   REFL_DC |   88  W
%    REFL_I |   22 nW
%    REFL_Q |   23 nW
% TRANSa_DC |    6  W
% TRANSb_DC |    6  W
%     IX_DC |   12 kW
%     EX_DC |   12 kW
%
% See also SHOWFDC

% Tobin Fricke <tobin.fricke@ligo.org> July 2011

% minimal sanity check
if ~isequal(size(sigDC),[opt.Nprobe 1])
    error('This opt and sigDC don''t seem to go together');
end

% generate a cell array of probe names
labels = cellfun(@(sn) getProbeName(opt, sn), num2cell(1:opt.Nprobe), ...
    'UniformOutput', false);

% how long is the longest label?
max_label_len = max(cellfun(@length, labels));

% how long do we want them to be?
label_len = max(max_label_len, length('probe'));

% use sprintf to right-justify the row label
label_fmtstr = sprintf('%% %ds | ', label_len);

fprintf('\n');
fprintf(label_fmtstr, 'probe');
fprintf('power\n');
% print out the "---+--------" line
fprintf('%s\n', [ repmat('-', 1, label_len + 1) '+' ...
    repmat('-', 1, 9)]);

% print out the power at each probe:
for sn=1:opt.Nprobe,
    [prefix, value] = metricize(sigDC(sn));
    fprintf(label_fmtstr, labels{sn});
    if value < 10
        precision = 1;  % 3.1  (one decimal)
    else
        precision = 0;  % 137  (no decimals)
    end
    if value == 0
        fprintf(' ---  W\n');
    else
        fprintf(' %3.*f %sW\n', precision, value, prefix);
    end
end
fprintf('\n');
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