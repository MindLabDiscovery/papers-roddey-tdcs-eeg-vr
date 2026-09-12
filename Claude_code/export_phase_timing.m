function export_phase_timing(protocolfolder, outCsv)
% EXPORT_PHASE_TIMING
%
% QUESTION
%   S3_EEGanalysis.m gives every epoch a COMMON fixed length:
%
%       min_epochlength = min(diff(sort([all cueEvent times;
%                                        all targetUp times])));
%       epochs.vrevents.(block).(type).val(:,2) = val(:,1) + min_epochlength;
%
%   Each epoch therefore starts at its own event but ends a fixed interval
%   later, rather than at the next event. Where a phase is SHORTER than
%   min_epochlength, the epoch runs past the following event and includes
%   data from the next phase.
%
%   Movement duration averages 0.885 s with 82.5% of reaches under one
%   second, so Move epochs are the ones at risk. This script quantifies it.
%
%   Note also that min_epochlength is computed from cueEvent and targetUp
%   times only; atStartPosition is not included, though the resulting
%   length is applied to Hold epochs as well.
%
% WHAT IS WRITTEN
%   One row per reach, per block, per subject:
%       atStartPosition, cueEvent, targetUp times (seconds)
%       next atStartPosition time
%       hold_dur  = cueEvent - atStartPosition
%       prep_dur  = targetUp - cueEvent
%       move_dur  = next atStartPosition - targetUp
%       min_epochlength for that subject
%       three flags: does the fixed epoch exceed the true phase duration?
%
% INPUT
%   <protocolfolder>/<subject>/analysis/S1-VR_preproc/<subject>_S1-VRdata_preprocessed.mat
%   Loaded for trialData.vr(i).events and the sampling rate.
%
% OUTPUT
%   phase_timing.csv          per-reach detail
%   phase_timing_summary.csv  per subject x block x phase overrun rates
%   console: the answer, per phase
%
% USAGE
%   export_phase_timing('D:\...\data_raw','phase_timing.csv')

if nargin < 2 || isempty(outCsv), outCsv = 'phase_timing.csv'; end

roster = {
 'pro00087153_0003','CS','Stim'; 'pro00087153_0004','CS','Stim'
 'pro00087153_0005','CS','Stim'; 'pro00087153_0042','CS','Stim'
 'pro00087153_0043','CS','Stim'
 'pro00087153_0013','CS','Sham'; 'pro00087153_0015','CS','Sham'
 'pro00087153_0017','CS','Sham'; 'pro00087153_0018','CS','Sham'
 'pro00087153_0021','CS','Sham'
 'pro00087153_0022','HC','Stim'; 'pro00087153_0024','HC','Stim'
 'pro00087153_0025','HC','Stim'; 'pro00087153_0026','HC','Stim'
 'pro00087153_0029','HC','Stim'
 'pro00087153_0020','HC','Sham'; 'pro00087153_0023','HC','Sham'
 'pro00087153_0027','HC','Sham'; 'pro00087153_0028','HC','Sham'
 'pro00087153_0036','HC','Sham'
};
blockLabels = {'BL','ES','LS','Post'};

rows = {};
fprintf('Extracting phase timing for %d subjects...\n\n', size(roster,1));

for s = 1:size(roster,1)
    subject = roster{s,1}; grp = roster{s,2}; cond = roster{s,3};
    f = fullfile(protocolfolder, subject, 'analysis', 'S1-VR_preproc', ...
                 [subject '_S1-VRdata_preprocessed.mat']);
    if exist(f,'file')~=2
        fprintf('  [%2d] %s : MISSING S1 file\n', s, subject); continue
    end
    fprintf('  [%2d/%2d] %s ... ', s, size(roster,1), subject);
    try
        D = load(f,'trialData'); trialData = D.trialData; clear D
    catch ME
        fprintf('LOAD FAILED (%s)\n', ME.message); continue
    end

    nBlocks = numel(trialData.vr);

    % --- reproduce min_epochlength exactly as S3_EEGanalysis computes it ---
    pool = [];
    for i = 1:nBlocks
        ev = trialData.vr(i).events;
        if isfield(ev,'cueEvent'), pool = [pool; ev.cueEvent.time(:)]; end %#ok<AGROW>
        if isfield(ev,'targetUp'), pool = [pool; ev.targetUp.time(:)]; end %#ok<AGROW>
    end
    if numel(pool) < 2
        fprintf('insufficient events\n'); continue
    end
    minEpoch = min(diff(sort(pool)));      % seconds

    for i = 1:min(nBlocks, numel(blockLabels))
        ev = trialData.vr(i).events;
        if ~isfield(ev,'atStartPosition') || ~isfield(ev,'cueEvent') || ...
           ~isfield(ev,'targetUp')
            continue
        end
        aSP = ev.atStartPosition.time(:);
        cue = ev.cueEvent.time(:);
        tUp = ev.targetUp.time(:);
        n   = min([numel(aSP) numel(cue) numel(tUp)]);

        for r = 1:n
            % Move ends at the NEXT atStartPosition; last reach uses taskEnd
            if r < numel(aSP)
                nextStart = aSP(r+1);
            elseif isfield(ev,'taskEnd')
                nextStart = ev.taskEnd.time(1);
            else
                nextStart = NaN;
            end
            holdDur = cue(r) - aSP(r);
            prepDur = tUp(r) - cue(r);
            moveDur = nextStart - tUp(r);

            rows(end+1,:) = { subject, grp, cond, blockLabels{i}, r, ...
                aSP(r), cue(r), tUp(r), nextStart, ...
                holdDur, prepDur, moveDur, minEpoch, ...
                double(minEpoch > holdDur), double(minEpoch > prepDur), ...
                double(minEpoch > moveDur) }; %#ok<AGROW>
        end
    end
    clear trialData
    fprintf('minEpoch = %.3f s\n', minEpoch);
end

hdr = {'subject','group','condition','block','reach', ...
       'atStartPosition_s','cueEvent_s','targetUp_s','nextStart_s', ...
       'hold_dur_s','prep_dur_s','move_dur_s','min_epochlength_s', ...
       'hold_overrun','prep_overrun','move_overrun'};
T = cell2table(rows,'VariableNames',hdr);
writetable(T,outCsv);
fprintf('\nWritten: %s (%d reaches)\n\n', outCsv, height(T));

%% ---- summary ----------------------------------------------------------
sumRows = {};
subs = unique(T.subject,'stable');
for i = 1:numel(subs)
    for b = 1:numel(blockLabels)
        m = strcmp(T.subject,subs{i}) & strcmp(T.block,blockLabels{b});
        if ~any(m), continue; end
        ti = T(m,:);
        sumRows(end+1,:) = { subs{i}, ti.group{1}, ti.condition{1}, ...
            blockLabels{b}, height(ti), ti.min_epochlength_s(1), ...
            mean(ti.hold_dur_s,'omitnan'), mean(ti.prep_dur_s,'omitnan'), ...
            mean(ti.move_dur_s,'omitnan'), ...
            100*mean(ti.hold_overrun), 100*mean(ti.prep_overrun), ...
            100*mean(ti.move_overrun) }; %#ok<AGROW>
    end
end
S2 = cell2table(sumRows,'VariableNames', ...
    {'subject','group','condition','block','n_reaches','min_epochlength_s', ...
     'mean_hold_s','mean_prep_s','mean_move_s', ...
     'pct_hold_overrun','pct_prep_overrun','pct_move_overrun'});
[p,n,e] = fileparts(outCsv);
writetable(S2, fullfile(p,[n '_summary' e]));

%% ---- the answer -------------------------------------------------------
fprintf('================================================================\n');
fprintf('  DOES THE FIXED EPOCH OVERRUN THE PHASE IT LABELS?\n');
fprintf('================================================================\n');
fprintf('An overrun means the epoch extends past the next event and\n');
fprintf('includes data from the following phase.\n\n');
fprintf('min_epochlength across subjects: %.3f +/- %.3f s (range %.3f-%.3f)\n\n', ...
    mean(S2.min_epochlength_s), std(S2.min_epochlength_s), ...
    min(S2.min_epochlength_s), max(S2.min_epochlength_s));
fprintf('%-8s %12s %12s %14s\n','phase','mean dur (s)','epoch (s)','%% overrunning');
fprintf('%s\n',repmat('-',1,50));
fprintf('%-8s %12.3f %12.3f %13.1f%%\n','Hold', mean(T.hold_dur_s,'omitnan'), ...
    mean(T.min_epochlength_s), 100*mean(T.hold_overrun));
fprintf('%-8s %12.3f %12.3f %13.1f%%\n','Prep', mean(T.prep_dur_s,'omitnan'), ...
    mean(T.min_epochlength_s), 100*mean(T.prep_overrun));
fprintf('%-8s %12.3f %12.3f %13.1f%%\n','Move', mean(T.move_dur_s,'omitnan'), ...
    mean(T.min_epochlength_s), 100*mean(T.move_overrun));

fprintf('\nBy block, Move phase only (the phase most at risk):\n');
fprintf('%-8s %12s %14s\n','block','mean move (s)','%% overrunning');
for b = 1:numel(blockLabels)
    m = strcmp(T.block,blockLabels{b});
    if ~any(m), continue; end
    fprintf('%-8s %12.3f %13.1f%%\n', blockLabels{b}, ...
        mean(T.move_dur_s(m),'omitnan'), 100*mean(T.move_overrun(m)));
end

fprintf(['\nINTERPRETATION\n' ...
    '  A low overrun rate means epochs stay within their phase and the\n' ...
    '  labels are clean.\n' ...
    '  A high rate in Move means Move-phase results include post-movement\n' ...
    '  data, which bears directly on the Move-phase coherence finding and\n' ...
    '  should be stated in the Methods.\n']);
fprintf('================================================================\n');

end
