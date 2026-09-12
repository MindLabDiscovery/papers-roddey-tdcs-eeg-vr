%% extract_kinematics.m
%
% Purpose:
%   Flattens subjectData(i).kinematics.data -- a 1x13 cell, each cell a
%   12x4 double (reaches x blocks) -- into a single long-format CSV:
%   one row per subject x block x reach x metric combination.
%   624 rows per subject (4 blocks x 12 reaches x 13 metrics).
%
% Roster:
%   Explicit, hardcoded, CRF-verified 20-subject roster (10 CS, 10 HC),
%   per HANDOFF section 6 policy: "All scripts use explicit hardcoded
%   rosters, never directory listings." Subject 0030 (parallel
%   Parkinson's protocol, sits on disk at subjectData row 18) is
%   deliberately excluded. Subjects are matched by NAME, never by row
%   index -- 0030's row position must never leak in implicitly.
%
% Group (CS/HC) assignment:
%   Preferentially read from subjectData(i).sessioninfo.dx, which is
%   the authoritative hand-entered field. Falls back to a CRF-derived
%   guess (based on stroke/no-stroke language on the case report forms)
%   ONLY if sessioninfo.dx is missing or empty, and prints a loud
%   warning when it does -- verify any subject flagged this way before
%   trusting the Group column downstream.
%
% Requires: subjectData.mat on path (adjust DATA_PATH below).
% Tested against: MATLAB R2019b. No toolboxes required (no FieldTrip/
%   ReMAE dependency -- restoredefaultpath not needed for this script).
%
% Output: kinematics_long.csv, columns:
%   SubjectID, Group, GroupSource, Block, BlockIdx, Reach, Metric,
%   MetricIdx, Value

clear; clc;

%% ---- CONFIG ----
DATA_PATH = 'C:\Users\ncr200\Downloads\data_raw\subjectData.mat';
OUT_PATH  = fullfile(pwd, 'kinematics_long.csv');

% Explicit hardcoded roster (CRF-verified, 20 subjects: 10 CS, 10 HC).
% First 10 entries are CS, next 10 are HC -- see group_labels below.
% DO NOT derive this list from a directory listing or from subjectData
% row indices directly.
roster = { ...
    '0003', '0004', '0005', '0013', '0015', '0017', '0018', '0021', ...
    '0042', '0043', ...   % CS (chronic stroke)
    '0020', '0022', '0023', '0024', '0025', '0026', '0027', '0028', ...
    '0029', '0036' ...    % HC (healthy control)
};

n_cs = 10;  % first n_cs roster entries are CS; remainder are HC
fallback_group_labels = [repmat({'CS'}, 1, n_cs), ...
                          repmat({'HC'}, 1, numel(roster) - n_cs)];

block_labels = {'BL', 'ES', 'LS', 'Post'};  % columns 1-4 of each 12x4 matrix
n_reaches = 12;
n_blocks  = 4;
n_metrics_expected = 13;

%% ---- LOAD ----
fprintf('Loading %s ...\n', DATA_PATH);
if ~isfile(DATA_PATH)
    error('extract_kinematics:fileNotFound', ...
        'DATA_PATH does not exist: %s -- edit DATA_PATH at the top of this script.', ...
        DATA_PATH);
end
S = load(DATA_PATH);
if ~isfield(S, 'subjectData')
    error('extract_kinematics:missingVar', ...
        'subjectData not found in %s', DATA_PATH);
end
subjectData = S.subjectData;
all_names = {subjectData.SubjectName};

%% ---- BUILD LONG-FORMAT TABLE ----
rows = {};  % accumulate as cell rows; ~12,480 rows total, fine to grow

for si = 1:numel(roster)
    subj_id = roster{si};
    fallback_group = fallback_group_labels{si};

    % Match by NAME, never by index (0030 caveat -- HANDOFF sec 6)
    match_idx = find(contains(all_names, subj_id), 1);
    if isempty(match_idx)
        warning('extract_kinematics:notFound', ...
            'Subject %s not found in subjectData -- skipping.', subj_id);
        continue;
    end

    % --- Group: prefer sessioninfo.dx, fall back to CRF-derived guess ---
    % Normalized to 'CS'/'HC' regardless of source so the Group column
    % is consistent for downstream filtering either way.
    group = '';
    group_source = '';
    si_struct = subjectData(match_idx).sessioninfo;
    if isstruct(si_struct) && isfield(si_struct, 'dx') && ~isempty(si_struct.dx)
        dx_raw = lower(strtrim(char(string(si_struct.dx))));
        switch dx_raw
            case 'stroke'
                group = 'CS';
            case 'healthy'
                group = 'HC';
            otherwise
                warning('extract_kinematics:unrecognizedDx', ...
                    ['Subject %s: sessioninfo.dx = "%s" not recognized ' ...
                     '(expected "stroke" or "healthy") -- using raw value as-is.'], ...
                    subj_id, dx_raw);
                group = dx_raw;
        end
        group_source = 'sessioninfo.dx';
    else
        group = fallback_group;
        group_source = 'CRF-derived-guess-VERIFY';
        warning('extract_kinematics:groupFallback', ...
            ['Subject %s: sessioninfo.dx missing/empty -- using CRF-derived ' ...
             'guess "%s". VERIFY before trusting downstream.'], subj_id, group);
    end

    % --- Kinematics ---
    kin = subjectData(match_idx).kinematics;
    if ~isfield(kin, 'data') || ~isfield(kin, 'label')
        warning('extract_kinematics:missingFields', ...
            'Subject %s missing kinematics.data or kinematics.label -- skipping.', subj_id);
        continue;
    end

    data   = kin.data;    % 1x13 cell, each 12x4 (reaches x blocks)
    labels = kin.label;   % 1x13 cell of metric names

    if numel(data) ~= n_metrics_expected || numel(labels) ~= n_metrics_expected
        warning('extract_kinematics:unexpectedShape', ...
            'Subject %s: expected %d kinematic metrics, found %d data / %d labels.', ...
            subj_id, n_metrics_expected, numel(data), numel(labels));
    end

    for m = 1:numel(data)
        metric_name = labels{m};
        if iscell(metric_name) || isstring(metric_name)
            metric_name = char(metric_name);
        end
        mat = data{m};  % expected 12 x 4

        if ~isequal(size(mat), [n_reaches n_blocks])
            warning('extract_kinematics:unexpectedSize', ...
                'Subject %s, metric %s: expected %dx%d, got %dx%d -- skipping metric.', ...
                subj_id, metric_name, n_reaches, n_blocks, size(mat,1), size(mat,2));
            continue;
        end

        for b = 1:n_blocks
            for r = 1:n_reaches
                rows(end+1, :) = { subj_id, group, group_source, ...
                    block_labels{b}, b, r, metric_name, m, mat(r, b) }; %#ok<AGROW>
            end
        end
    end

    fprintf('  %s (%s, source=%s): OK\n', subj_id, group, group_source);
end

%% ---- WRITE CSV ----
varnames = {'SubjectID', 'Group', 'GroupSource', 'Block', 'BlockIdx', ...
            'Reach', 'Metric', 'MetricIdx', 'Value'};
T = cell2table(rows, 'VariableNames', varnames);

expected_rows = numel(roster) * n_blocks * n_reaches * n_metrics_expected;
fprintf('\nTotal rows: %d (expected %d = %d subjects x %d)\n', ...
    height(T), expected_rows, numel(roster), n_blocks * n_reaches * n_metrics_expected);
if height(T) ~= expected_rows
    warning('extract_kinematics:rowCountMismatch', ...
        'Row count does not match expected %d -- check warnings above for skipped subjects/metrics.', ...
        expected_rows);
end

writetable(T, OUT_PATH);
fprintf('Wrote %s\n', OUT_PATH);
