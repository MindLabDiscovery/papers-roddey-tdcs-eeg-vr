function export_epoch_retention(protocolfolder, outCsv)
% EXPORT_EPOCH_RETENTION
% Produces the data-retention quantification required by:
%   - Reviewer 2, Methods comment 10 ("how much data did this equate to?")
%   - Reviewer 1, Major point 3 (clean epoch counts inside vs outside the
%     stimulation window, to show gamma is not residual stimulation artifact)
%   - Reviewer 1, Methods/Participants (C3-C4 availability per participant)
%   - Reviewer 2, Results comment 1 (how many participants had C3/C4)
%
% For every subject x block x phase it records:
%   retained epochs, epoch duration, total retained seconds,
%   bad channels removed (count and identity), whether C3/C4 were
%   interpolated, and channel/epoch rejection rates.
%
% USAGE
%   export_epoch_retention('D:\Roddey_tdcs_eeg\Data\data_raw', 'epoch_retention.csv')
%
% NOTES
%   - Loads eegevents_ft (phase-split) from each subject's EEGlab_Total.mat.
%     These files are large; subjects are processed one at a time and cleared.
%   - Subject 0030 is intentionally EXCLUDED (recorded under the parallel
%     Parkinson's protocol; see response to Reviewer 2, Methods comment 2).
%   - Writes two files: the per-phase CSV and a per-subject summary CSV.

if nargin < 2 || isempty(outCsv), outCsv = 'epoch_retention.csv'; end

% -------------------------------------------------------------------------
% Subject roster - 20 participants, 5 per subgroup
% EDIT THIS if any assignment is wrong.
% -------------------------------------------------------------------------
roster = {
% subjectID              group     condition
 'pro00087153_0003',   'CS',   'Stim'
 'pro00087153_0004',   'CS',   'Stim'
 'pro00087153_0005',   'CS',   'Stim'
 'pro00087153_0042',   'CS',   'Stim'
 'pro00087153_0043',   'CS',   'Stim'
 'pro00087153_0013',   'CS',   'Sham'
 'pro00087153_0015',   'CS',   'Sham'
 'pro00087153_0017',   'CS',   'Sham'
 'pro00087153_0018',   'CS',   'Sham'
 'pro00087153_0021',   'CS',   'Sham'
 'pro00087153_0022',   'HC',   'Stim'
 'pro00087153_0024',   'HC',   'Stim'
 'pro00087153_0025',   'HC',   'Stim'
 'pro00087153_0026',   'HC',   'Stim'
 'pro00087153_0029',   'HC',   'Stim'
 'pro00087153_0020',   'HC',   'Sham'
 'pro00087153_0023',   'HC',   'Sham'
 'pro00087153_0027',   'HC',   'Sham'
 'pro00087153_0028',   'HC',   'Sham'
 'pro00087153_0036',   'HC',   'Sham'
};

blockNames  = {'t1','t2','t3','t4'};
blockLabels = {'BL','ES','LS','Post'};    % baseline, early stim, late stim, post
phaseNames  = {'Hold','Prep','Move'};
STIM_BLOCKS = [false true true false];    % ES and LS are during stimulation

rows = {};   % accumulate output

fprintf('Processing %d subjects...\n\n', size(roster,1));

for s = 1:size(roster,1)

    subject = roster{s,1};
    grp     = roster{s,2};
    cond    = roster{s,3};

    totalFile = fullfile(protocolfolder, subject, 'analysis', 'EEGlab', 'EEGlab_Total.mat');

    if exist(totalFile,'file') ~= 2
        fprintf('  [%2d/%2d] %s : MISSING EEGlab_Total.mat -- SKIPPED\n', s, size(roster,1), subject);
        rows(end+1,:) = {subject, grp, cond, 'NA','NA','NA', NaN,NaN,NaN,NaN,NaN,'FILE_MISSING','NA','NA'}; %#ok<AGROW>
        continue
    end

    fprintf('  [%2d/%2d] %s (%s %s) ... ', s, size(roster,1), subject, grp, cond);

    try
        S  = load(totalFile, 'eegevents_ft');
        if ~isfield(S,'eegevents_ft')
            S = load(totalFile, 'eegevents_tfa');
            ev = S.eegevents_tfa;
        else
            ev = S.eegevents_ft;
        end
        clear S
    catch ME
        fprintf('LOAD FAILED (%s)\n', ME.message);
        rows(end+1,:) = {subject, grp, cond, 'NA','NA','NA', NaN,NaN,NaN,NaN,NaN,'LOAD_FAILED','NA','NA'}; %#ok<AGROW>
        continue
    end

    for b = 1:numel(blockNames)

        bn = blockNames{b};
        if ~isfield(ev.trials, bn)
            rows(end+1,:) = {subject, grp, cond, blockLabels{b}, 'NA', ...
                             logical2str(STIM_BLOCKS(b)), NaN,NaN,NaN,NaN,NaN, ...
                             'BLOCK_ABSENT','NA','NA'}; %#ok<AGROW>
            continue
        end

        wk = ev.trials.(bn);

        for p = 1:min(3, size(wk,1))

            peeg = wk(p,:);

            if isempty(peeg) || ~isfield(peeg,'setname') || isempty(peeg.setname)
                rows(end+1,:) = {subject, grp, cond, blockLabels{b}, phaseNames{p}, ...
                                 logical2str(STIM_BLOCKS(b)), NaN,NaN,NaN,NaN,NaN, ...
                                 'PHASE_EMPTY','NA','NA'}; %#ok<AGROW>
                continue
            end

            % --- epoch counts -------------------------------------------
            nEpochs = size(peeg.data, 3);
            nSamp   = size(peeg.data, 2);
            srate   = peeg.srate;
            epochSec = nSamp / srate;
            totalSec = nEpochs * epochSec;

            % --- analysis window actually used for coherence (times >= 0)
            postIdx  = peeg.times >= 0;
            postSec  = sum(postIdx) / srate;

            % --- bad channels -------------------------------------------
            badList = [];
            if isfield(peeg,'badChannels') && isfield(peeg.badChannels,'channels')
                bc = peeg.badChannels.channels;
                if ~any(isnan(bc(:))), badList = bc(:)'; end
            end
            nBad = numel(badList);

            % --- channel labels for bad channels ------------------------
            if ~isempty(badList) && isfield(peeg,'chanlocs')
                lbls = {peeg.chanlocs.labels};
                valid = badList(badList >= 1 & badList <= numel(lbls));
                badStr = strjoin(lbls(valid), '|');
            else
                badStr = '';
            end

            % --- was C3 or C4 interpolated? -----------------------------
            c3int = 'no'; c4int = 'no';
            if isfield(peeg,'chanlocs')
                lbls = {peeg.chanlocs.labels};
                iC3 = find(strcmpi(lbls,'C3'),1);
                iC4 = find(strcmpi(lbls,'C4'),1);
                if ~isempty(iC3) && ismember(iC3, badList), c3int = 'YES'; end
                if ~isempty(iC4) && ismember(iC4, badList), c4int = 'YES'; end
            end

            rows(end+1,:) = {subject, grp, cond, blockLabels{b}, phaseNames{p}, ...
                             logical2str(STIM_BLOCKS(b)), ...
                             nEpochs, epochSec, totalSec, postSec, nBad, ...
                             badStr, c3int, c4int}; %#ok<AGROW>
        end
    end

    clear ev
    fprintf('done\n');
end

% -------------------------------------------------------------------------
% Write per-phase CSV
% -------------------------------------------------------------------------
hdr = {'subject','group','condition','block','phase','during_stim', ...
       'n_epochs','epoch_sec','total_sec','coh_window_sec','n_bad_channels', ...
       'bad_channel_labels','C3_interpolated','C4_interpolated'};

T = cell2table(rows, 'VariableNames', hdr);
writetable(T, outCsv);
fprintf('\nPer-phase table written to: %s  (%d rows)\n', outCsv, height(T));

% -------------------------------------------------------------------------
% Per-subject summary + the pre-vs-during-stimulation comparison
% (this is the table that answers Reviewer 1, Major point 3)
% -------------------------------------------------------------------------
sumRows = {};
subs = unique(T.subject, 'stable');
for i = 1:numel(subs)
    ti = T(strcmp(T.subject, subs{i}), :);
    if isempty(ti), continue; end

    isStim = strcmp(ti.during_stim,'yes');
    preEp  = nanmean(ti.n_epochs(~isStim));
    stimEp = nanmean(ti.n_epochs(isStim));

    sumRows(end+1,:) = { subs{i}, ti.group{1}, ti.condition{1}, ...
        nansum(ti.n_epochs), nanmean(ti.n_epochs), ...
        preEp, stimEp, ...
        (stimEp - preEp), ...
        nanmean(ti.n_bad_channels), ...
        sum(strcmp(ti.C3_interpolated,'YES')), ...
        sum(strcmp(ti.C4_interpolated,'YES')) }; %#ok<AGROW>
end

sumHdr = {'subject','group','condition','total_epochs','mean_epochs_per_cell', ...
          'mean_epochs_prestim','mean_epochs_duringstim','epoch_diff_stim_minus_pre', ...
          'mean_bad_channels','n_cells_C3_interpolated','n_cells_C4_interpolated'};

S2 = cell2table(sumRows, 'VariableNames', sumHdr);
[pth,nm,ext] = fileparts(outCsv);
sumCsv = fullfile(pth, [nm '_summary' ext]);
writetable(S2, sumCsv);
fprintf('Per-subject summary written to: %s\n\n', sumCsv);

% -------------------------------------------------------------------------
% Console report: the numbers needed for the response letter
% -------------------------------------------------------------------------
fprintf('========================================================\n');
fprintf(' RETENTION SUMMARY BY SUBGROUP\n');
fprintf('========================================================\n');
groups = {'CS','Stim'; 'CS','Sham'; 'HC','Stim'; 'HC','Sham'};
for g = 1:size(groups,1)
    sel = strcmp(T.group,groups{g,1}) & strcmp(T.condition,groups{g,2});
    if ~any(sel), continue; end
    tg = T(sel,:);
    isStim = strcmp(tg.during_stim,'yes');
    fprintf('%s %s (n=%d subjects)\n', groups{g,1}, groups{g,2}, numel(unique(tg.subject)));
    fprintf('   epochs/cell  pre-stim  : %6.2f +/- %5.2f\n', nanmean(tg.n_epochs(~isStim)), nanstd(tg.n_epochs(~isStim)));
    fprintf('   epochs/cell  during    : %6.2f +/- %5.2f\n', nanmean(tg.n_epochs(isStim)),  nanstd(tg.n_epochs(isStim)));
    fprintf('   bad channels pre-stim  : %6.2f\n', nanmean(tg.n_bad_channels(~isStim)));
    fprintf('   bad channels during    : %6.2f\n', nanmean(tg.n_bad_channels(isStim)));
    fprintf('   C3 interpolated cells  : %d / %d\n', sum(strcmp(tg.C3_interpolated,'YES')), height(tg));
    fprintf('   C4 interpolated cells  : %d / %d\n\n', sum(strcmp(tg.C4_interpolated,'YES')), height(tg));
end

% Key statistical test for Reviewer 1, Major point 3
isStimAll = strcmp(T.during_stim,'yes');
x = T.n_epochs(~isStimAll); y = T.n_epochs(isStimAll);
x = x(~isnan(x)); y = y(~isnan(y));
if ~isempty(x) && ~isempty(y)
    [~,pv,~,st] = ttest2(x,y);
    fprintf('Epoch retention, pre-stim vs during-stim (all participants):\n');
    fprintf('   pre    : %.2f +/- %.2f  (n=%d cells)\n', mean(x), std(x), numel(x));
    fprintf('   during : %.2f +/- %.2f  (n=%d cells)\n', mean(y), std(y), numel(y));
    fprintf('   t(%d) = %.3f, p = %.4f\n', st.df, st.tstat, pv);
    fprintf('   >> If p is non-significant, this supports the claim that\n');
    fprintf('      data quality was comparable inside and outside the\n');
    fprintf('      stimulation window (Reviewer 1, Major point 3).\n');
end
fprintf('========================================================\n');

end % main

% =========================================================================
function s = logical2str(tf)
if tf, s = 'yes'; else, s = 'no'; end
end
