function inspect_kinematics(subjectDataPath, s2MetricsPath)
% INSPECT_KINEMATICS
%
% Prints the nested field structure of the kinematic data so an extractor can
% be written against what is actually there rather than guessed at.
%
% Run this, then send me the console output (or save it with `diary`).
%
% USAGE
%   inspect_kinematics('C:\Users\ncr200\Downloads\data_raw\subjectData.mat')
%
%   % optionally also inspect a subject's S2-Metrics file:
%   inspect_kinematics(sdPath, ...
%     'C:\...\pro00087153_0003\analysis\S2-metrics\pro00087153_0003_S2-Metrics.mat')
%
% TO CAPTURE THE OUTPUT
%   diary('C:\Users\ncr200\Downloads\kin_structure.txt')
%   inspect_kinematics(...)
%   diary off

if nargin < 2, s2MetricsPath = ''; end

MAXDEPTH = 4;

fprintf('==================================================================\n');
fprintf(' subjectData.mat\n');
fprintf('==================================================================\n');
assert(exist(subjectDataPath,'file')==2,'Not found: %s',subjectDataPath);

S = load(subjectDataPath);
fn = fieldnames(S);
fprintf('top-level variables: %s\n\n', strjoin(fn', ', '));

if ~ismember('subjectData', fn)
    fprintf('(no variable named subjectData; inspecting %s instead)\n', fn{1});
    sd = S.(fn{1});
else
    sd = S.subjectData;
end
clear S

fprintf('subjectData: %s, size %s\n', class(sd), mat2str(size(sd)));
fprintf('fields: %s\n\n', strjoin(fieldnames(sd)', ', '));

% ---- subject order, by name (indices are NOT reliable: row 18 is 0030) --
fprintf('------------------------------------------------------------------\n');
fprintf(' SUBJECT ORDER (map by name, never by index)\n');
fprintf('------------------------------------------------------------------\n');
for i = 1:numel(sd)
    nm = '';
    if isfield(sd,'SubjectName')
        v = sd(i).SubjectName;
        if ischar(v), nm = v; elseif iscell(v) && ~isempty(v), nm = v{1}; end
    end
    fprintf('  [%2d] %s\n', i, nm);
end

% ---- kinematics structure ----------------------------------------------
fprintf('\n------------------------------------------------------------------\n');
fprintf(' subjectData(1).kinematics\n');
fprintf('------------------------------------------------------------------\n');
if isfield(sd,'kinematics')
    describe(sd(1).kinematics, 'kinematics', 0, MAXDEPTH);
else
    fprintf('  (no kinematics field)\n');
end

% ---- sessioninfo: needed for anode laterality in healthy controls -------
fprintf('\n------------------------------------------------------------------\n');
fprintf(' subjectData(1).sessioninfo   (stimulation laterality lives here)\n');
fprintf('------------------------------------------------------------------\n');
if isfield(sd,'sessioninfo')
    describe(sd(1).sessioninfo, 'sessioninfo', 0, 2);
    % print stimlat for every subject if present
    if isfield(sd(1).sessioninfo,'stimlat')
        fprintf('\n  stimlat by subject:\n');
        for i = 1:numel(sd)
            nm = ''; if isfield(sd,'SubjectName'), nm = tostr(sd(i).SubjectName); end
            fprintf('    %-22s %s\n', nm, tostr(sd(i).sessioninfo.stimlat));
        end
    end
else
    fprintf('  (no sessioninfo field)\n');
end

% ---- S2-Metrics --------------------------------------------------------
if ~isempty(s2MetricsPath) && exist(s2MetricsPath,'file')==2
    fprintf('\n==================================================================\n');
    fprintf(' S2-Metrics.mat\n');
    fprintf('==================================================================\n');
    M = load(s2MetricsPath,'metricdat');
    if isfield(M,'metricdat')
        describe(M.metricdat,'metricdat',0,MAXDEPTH);
    end
end

fprintf('\n==================================================================\n');
fprintf(' WHAT I NEED FROM THIS\n');
fprintf('==================================================================\n');
fprintf(' 1. Where maximum acceleration lives, and its shape.\n');
fprintf(' 2. How trials/blocks are indexed (is there a 1x4 dimension for\n');
fprintf('    BL/ES/LS/Post, or a trial-number field?).\n');
fprintf(' 3. Whether values are per-reach (12 per block) or already averaged.\n');
fprintf(' 4. The stimlat values, so healthy-control anode side can be filled in.\n');
fprintf('==================================================================\n');

end

% =========================================================================
function describe(x, name, depth, maxdepth)
pad = repmat('  ', 1, depth+1);

if depth > maxdepth
    fprintf('%s%s: %s %s (deeper levels not shown)\n', pad, name, class(x), mat2str(size(x)));
    return
end

if isstruct(x)
    fprintf('%s%s: struct %s\n', pad, name, mat2str(size(x)));
    f = fieldnames(x);
    for i = 1:numel(f)
        try
            describe(x(1).(f{i}), f{i}, depth+1, maxdepth);
        catch
            fprintf('%s  %s: <unreadable>\n', pad, f{i});
        end
    end

elseif iscell(x)
    fprintf('%s%s: cell %s\n', pad, name, mat2str(size(x)));
    if ~isempty(x) && depth < maxdepth
        describe(x{1}, [name '{1}'], depth+1, maxdepth);
    end

elseif isnumeric(x) || islogical(x)
    sz = size(x);
    if numel(x) <= 8
        fprintf('%s%s: %s %s = %s\n', pad, name, class(x), mat2str(sz), mat2str(x,4));
    else
        fprintf('%s%s: %s %s   [min %.4g  max %.4g  mean %.4g]\n', pad, name, ...
            class(x), mat2str(sz), min(x(:)), max(x(:)), mean(x(:),'omitnan'));
    end

elseif ischar(x)
    fprintf('%s%s: char = ''%s''\n', pad, name, x);

else
    fprintf('%s%s: %s %s\n', pad, name, class(x), mat2str(size(x)));
end
end

function s = tostr(v)
if ischar(v), s = v;
elseif iscell(v) && ~isempty(v), s = tostr(v{1});
elseif isnumeric(v) && isscalar(v), s = num2str(v);
elseif isnumeric(v), s = mat2str(v);
else, s = ['<' class(v) '>'];
end
end
