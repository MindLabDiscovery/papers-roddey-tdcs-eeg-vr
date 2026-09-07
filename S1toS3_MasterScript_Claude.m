function S1toS3_MainScript_Claude(protocolfolder, gitpath)
% S1toS3_MainScript_Claude
%
% PURPOSE
%   Runs the S1-S3 analysis stages across all participants, so that the
%   full processing chain from raw data to the EEGLAB pipeline can be
%   reproduced from this repository.
%
% PROVENANCE - PLEASE READ
%   This driver was NOT used to produce the results in the manuscript.
%   Stages S1-S3 were originally executed per participant from the MATLAB
%   command line. This script was written after the fact, for the sole
%   purpose of making the analysis reproducible, and reproduces the same
%   sequence of calls in a loop. It is named with the _Claude suffix to
%   distinguish it from the scripts that were used in the original
%   analysis.
%
%   The subsequent EEGLAB pipeline is driven by EEGLab_MainScript.m, which
%   WAS used for the original analysis.
%
% SEQUENCE
%   S1_VR_trial_preproc   VR and EEG import, event extraction, sync
%   S2_MetricPlot_nredit  kinematic metrics; rejects reaches failing the
%                         completion and initiation-latency criteria, and
%                         removes their event times from trialData.vr
%   S3_EEGanalysis        epoch definition and spectral estimation
%
%   S2 must run before S3: S3 builds epochs from the event times that S2
%   leaves in place, so a reach rejected at S2 produces no epoch at S3.
%
% USAGE
%   S1toS3_MainScript_Claude('/path/to/data','/path/to/Allen-EEG-analysis')
%
%   Then run EEGLab_MainScript.m to execute the EEGLAB pipeline.
%
% NOTE ON FUNCTION NAMING
%   S2_MetricPlot_nredit.m internally declares "function S2_MetricPlot".
%   MATLAB dispatches on the FILE name, so the call below uses
%   S2_MetricPlot_nredit. Calling S2_MetricPlot would fail.

if nargin < 2 || isempty(gitpath); gitpath = pwd; end
if nargin < 1 || isempty(protocolfolder)
    error('protocolfolder must be supplied');
end

%% ---- Parameters -------------------------------------------------------
% CONFIRM THESE AGAINST THE ORIGINAL ANALYSIS BEFORE USE.
% They are not recorded anywhere in the repository, because S1-S3 were
% invoked interactively. The values below are placeholders.

S1_MANUAL    = false;   % S1: interactive review of trial segmentation
S2_THRESHOLD = [];      % S2: kinematic rejection threshold        <-- CONFIRM
S3_WINDOW    = [];      % S3: pwelch window length, seconds        <-- CONFIRM
S3_NOOVERLAP = [];      % S3: pwelch overlap (samples, or [])      <-- CONFIRM
S3_NFFT      = [];      % S3: pwelch nfft, seconds                 <-- CONFIRM
S3_MANUAL    = false;   % S3: interactive review

if isempty(S2_THRESHOLD) || isempty(S3_WINDOW) || isempty(S3_NFFT)
    error(['Parameters S2_THRESHOLD, S3_WINDOW, S3_NOOVERLAP and S3_NFFT ' ...
           'must be set before this script will run. They were supplied ' ...
           'interactively in the original analysis and are not recorded ' ...
           'in this repository. Note that S3 multiplies window and nfft ' ...
           'by the sampling frequency, so both are specified in seconds.']);
end

%% ---- Setup ------------------------------------------------------------
cd(gitpath)
allengit_genpaths(gitpath,'EEG')

sbj = dir(fullfile(protocolfolder,'pro000*'));
sbj = {sbj.name}';

% Subject 0030 is excluded from the analysis: that record belongs to a
% healthy participant enrolled in a parallel Parkinson's disease protocol
% and was inadvertently pooled during the original analysis.
sbj = sbj(~contains(sbj,'0030'));

fprintf('Running S1-S3 for %d participants\n', numel(sbj));
fprintf('Protocol folder: %s\n\n', protocolfolder);

status = cell(numel(sbj),3);

%% ---- Stage 1 ----------------------------------------------------------
% Not run in parfor: S1 may prompt for interactive review, and later stages
% depend on its output for the same subject.
fprintf('=== S1: VR and EEG preprocessing ===\n');
for i = 1:numel(sbj)
    fprintf('  [%2d/%2d] %s ... ', i, numel(sbj), sbj{i});
    try
        S1_VR_trial_preproc(sbj{i}, protocolfolder, S1_MANUAL);
        status{i,1} = 'complete';  fprintf('done\n');
    catch ME
        status{i,1} = ME;          fprintf('FAILED: %s\n', ME.message);
    end
end

%% ---- Stage 2 ----------------------------------------------------------
fprintf('\n=== S2: kinematic metrics and reach rejection ===\n');
for i = 1:numel(sbj)
    if ~ischar(status{i,1}); fprintf('  [%2d/%2d] %s skipped (S1 failed)\n', ...
            i, numel(sbj), sbj{i}); continue; end
    fprintf('  [%2d/%2d] %s ... ', i, numel(sbj), sbj{i});
    try
        S2_MetricPlot_nredit(sbj{i}, protocolfolder, S2_THRESHOLD);
        status{i,2} = 'complete';  fprintf('done\n');
    catch ME
        status{i,2} = ME;          fprintf('FAILED: %s\n', ME.message);
    end
end

%% ---- Stage 3 ----------------------------------------------------------
fprintf('\n=== S3: epoch definition and spectral estimation ===\n');
for i = 1:numel(sbj)
    if ~ischar(status{i,2}); fprintf('  [%2d/%2d] %s skipped (S2 failed)\n', ...
            i, numel(sbj), sbj{i}); continue; end
    fprintf('  [%2d/%2d] %s ... ', i, numel(sbj), sbj{i});
    try
        S3_EEGanalysis(sbj{i}, protocolfolder, S3_WINDOW, S3_NOOVERLAP, ...
                       S3_NFFT, S3_MANUAL);
        status{i,3} = 'complete';  fprintf('done\n');
    catch ME
        status{i,3} = ME;          fprintf('FAILED: %s\n', ME.message);
    end
end

%% ---- Summary ----------------------------------------------------------
fprintf('\n================================================\n');
fprintf('  SUMMARY\n');
fprintf('================================================\n');
fprintf('%-24s %10s %10s %10s\n','subject','S1','S2','S3');
for i = 1:numel(sbj)
    fprintf('%-24s', sbj{i});
    for s = 1:3
        if ischar(status{i,s}); fprintf(' %10s','ok');
        elseif isempty(status{i,s}); fprintf(' %10s','skipped');
        else; fprintf(' %10s','FAILED'); end
    end
    fprintf('\n');
end
nOK = sum(cellfun(@ischar, status(:,3)));
fprintf('\n%d of %d participants completed all three stages.\n', nOK, numel(sbj));
fprintf('Next: run EEGLab_MainScript.m to execute the EEGLAB pipeline.\n');

assignin('base','S1toS3_status',status);

end
