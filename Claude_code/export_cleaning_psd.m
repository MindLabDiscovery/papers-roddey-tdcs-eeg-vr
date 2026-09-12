function export_cleaning_psd(protocolfolder, outPrefix)
% EXPORT_CLEANING_PSD
%
% PURPOSE
%   Produce the group-level demonstration that preprocessing removes
%   artifact without removing signal, requested by Reviewer 2:
%   "Demonstration of the power spectra, signal-to-noise ratios before and
%   after cleaning is required."
%
%   Figure 3 currently shows this for one participant. This script produces
%   it for all twenty, in all four subgroups, by reading the intermediate
%   pipeline stages that EEGLAB_preprocessing.m attaches to the EEG
%   structure as processingData{1..9}.
%
% WHERE THE DATA COMES FROM
%   EEGLAB_preprocessing.m stores a snapshot at each pipeline stage when
%   opt.icarem.save_procPipeline is true, and runEEGlab.m saves the whole
%   structure to EEGlab_Total.mat. No separate pipeline.mat is written; the
%   file of that name was extracted by hand for one participant.
%
%   Stages, per EEGLAB_preprocessing.m:
%       1 import (1024 Hz)        6 ICA removed
%       2 downsample (256 Hz)     7 bad channels removed and interpolated
%       3 high-pass 0.5 Hz        8 window rejection / ASR
%       4 notch 60 Hz             9 reach epoched
%       5 epoched
%
%   BEFORE cleaning = stage 4 (filtered, nothing removed)
%   AFTER  cleaning = stage 8 (ICA, channel and window rejection applied)
%   These are the two the reviewer's question concerns; stages 1-3 are
%   filtering and stage 9 is re-epoching.
%
% OUTPUT
%   <outPrefix>_psd_by_subject.csv   PSD per subject, stage and frequency
%   <outPrefix>_psd_group.csv        group means
%   fig_cleaning_psd.png / .svg      four panels, before and after overlaid
%   console: band-wise change and an SNR proxy
%
% USAGE
%   export_cleaning_psd('D:\...\data_raw','cleaning')
%
% R2019b safe.

if nargin < 2 || isempty(outPrefix); outPrefix = 'cleaning'; end

%% ---- Configuration ----------------------------------------------------
STAGE_BEFORE = 4;          % notch filtered, nothing removed
STAGE_AFTER  = 8;          % after ICA, channel and window rejection
FS           = 256;        % stages 2 onward
NFFT_SEC     = 2;          % pwelch window, seconds
FMAX         = 100;        % upper limit written out
OUT_DIR      = fullfile(pwd,'cleaning_psd');
if ~exist(OUT_DIR,'dir'); mkdir(OUT_DIR); end

% Band definitions for the summary table
bands = { 'drift',[1 4]; 'theta',[4 8]; 'alpha',[8 13]; ...
          'beta',[13 30]; 'gamma',[30 50]; 'line',[58 62]; 'hf',[70 100] };

roster = {
 'pro00087153_0003','CS','active'; 'pro00087153_0004','CS','active'
 'pro00087153_0005','CS','active'; 'pro00087153_0042','CS','active'
 'pro00087153_0043','CS','active'
 'pro00087153_0013','CS','sham';   'pro00087153_0015','CS','sham'
 'pro00087153_0017','CS','sham';   'pro00087153_0018','CS','sham'
 'pro00087153_0021','CS','sham'
 'pro00087153_0022','HC','active'; 'pro00087153_0024','HC','active'
 'pro00087153_0025','HC','active'; 'pro00087153_0026','HC','active'
 'pro00087153_0029','HC','active'
 'pro00087153_0020','HC','sham';   'pro00087153_0023','HC','sham'
 'pro00087153_0027','HC','sham';   'pro00087153_0028','HC','sham'
 'pro00087153_0036','HC','sham'
};
cells = {'CS','active';'CS','sham';'HC','active';'HC','sham'};
cellLbl = {'Chronic stroke, active','Chronic stroke, sham', ...
           'Healthy control, active','Healthy control, sham'};

%% ---- Extract ----------------------------------------------------------
rows = {}; P = struct(); nOK = 0;
fprintf('Reading %d participants...\n\n', size(roster,1));

for s = 1:size(roster,1)
    subject = roster{s,1}; grp = roster{s,2}; cond = roster{s,3};
    f = fullfile(protocolfolder,subject,'analysis','EEGlab','EEGlab_Total.mat');
    if exist(f,'file')~=2
        fprintf('  [%2d] %s : MISSING\n', s, subject); continue
    end
    fprintf('  [%2d/%2d] %s ... ', s, size(roster,1), subject);
    try
        S = load(f,'eegevents_icarem'); ev = S.eegevents_icarem; clear S
    catch ME
        fprintf('LOAD FAILED (%s)\n', ME.message); continue
    end

    if ~isfield(ev,'trials'); fprintf('no trials field\n'); continue; end
    fn = fieldnames(ev.trials);

    % anodal electrode from stimulation side
    sl = '';
    if isfield(ev.trials.(fn{1}),'sessioninfo') && ...
       isfield(ev.trials.(fn{1}).sessioninfo,'stimlat')
        sl = upper(strtrim(char(string(ev.trials.(fn{1}).sessioninfo.stimlat))));
    end
    anode = 'C4'; if strcmp(sl,'L'); anode = 'C3'; end

    got = false;
    for b = 1:numel(fn)
        E = ev.trials.(fn{b});
        if ~isfield(E,'processingData'); continue; end
        pd = E.processingData;
        if numel(pd) < STAGE_AFTER; continue; end

        lbls = {E.chanlocs.labels};
        ci = find(strcmpi(lbls,anode),1);
        if isempty(ci); continue; end

        for st = [STAGE_BEFORE STAGE_AFTER]
            d = pd{st}.data;
            if iscell(d); d = d{1}; end          % stages 5+ are per-trial cells
            if ci > size(d,1); continue; end
            x = double(d(ci,:,1));
            x = x(isfinite(x));
            if numel(x) < 4*FS; continue; end
            [pxx,fx] = pwelch(x, hann(NFFT_SEC*FS), [], NFFT_SEC*FS, FS);
            keep = fx > 0 & fx <= FMAX;
            fx = fx(keep); pxx = 10*log10(pxx(keep));
            key = sprintf('s%d_b%d', st, b);
            P.(matlab.lang.makeValidName(subject)).(key) = pxx(:)';
            P.freq = fx(:)';
            for q = 1:numel(fx)
                rows(end+1,:) = {subject, grp, cond, anode, fn{b}, st, ...
                    fx(q), pxx(q)}; %#ok<AGROW>
            end
            got = true;
        end
    end
    clear ev
    if got; nOK = nOK + 1; fprintf('ok (anode %s)\n', anode);
    else;   fprintf('no processingData at stages %d/%d\n', STAGE_BEFORE, STAGE_AFTER); end
end

if isempty(rows)
    error(['No processingData found in any EEGlab_Total.mat. ' ...
           'opt.icarem.save_procPipeline may have been false when the ' ...
           'pipeline was run, in which case the intermediate stages were ' ...
           'not retained and this analysis cannot be produced.']);
end

T = cell2table(rows,'VariableNames', ...
    {'subject','group','condition','anode','block','stage','freq_Hz','power_dB'});
writetable(T, fullfile(OUT_DIR,[outPrefix '_psd_by_subject.csv']));
fprintf('\n%d of %d participants had usable pipeline stages.\n', nOK, size(roster,1));
fprintf('Written: %s\n', fullfile(OUT_DIR,[outPrefix '_psd_by_subject.csv']));

%% ---- Group means ------------------------------------------------------
fx = unique(T.freq_Hz);
G = struct(); grows = {};
for c = 1:size(cells,1)
    for st = [STAGE_BEFORE STAGE_AFTER]
        m = strcmp(T.group,cells{c,1}) & strcmp(T.condition,cells{c,2}) & T.stage==st;
        v = nan(1,numel(fx));
        for q = 1:numel(fx)
            v(q) = mean(T.power_dB(m & T.freq_Hz==fx(q)),'omitnan');
        end
        G(c).(sprintf('s%d',st)) = v;
        for q = 1:numel(fx)
            grows(end+1,:) = {cellLbl{c}, st, fx(q), v(q)}; %#ok<AGROW>
        end
    end
end
writetable(cell2table(grows,'VariableNames',{'Group','Stage','freq_Hz','mean_power_dB'}), ...
    fullfile(OUT_DIR,[outPrefix '_psd_group.csv']));

%% ---- Console summary --------------------------------------------------
fprintf('\n================================================================\n');
fprintf('  BAND POWER BEFORE (stage %d) AND AFTER (stage %d) CLEANING\n', ...
    STAGE_BEFORE, STAGE_AFTER);
fprintf('================================================================\n');
fprintf('Cleaning should reduce line noise and high-frequency content while\n');
fprintf('leaving the physiological bands comparatively intact.\n\n');
fprintf('%-24s %-7s %10s %10s %10s\n','group','band','before','after','change');
for c = 1:size(cells,1)
    for b = 1:size(bands,1)
        mb = fx>=bands{b,2}(1) & fx<=bands{b,2}(2);
        bef = mean(G(c).(sprintf('s%d',STAGE_BEFORE))(mb),'omitnan');
        aft = mean(G(c).(sprintf('s%d',STAGE_AFTER))(mb),'omitnan');
        fprintf('%-24s %-7s %10.2f %10.2f %+10.2f\n', ...
            cellLbl{c}, bands{b,1}, bef, aft, aft-bef);
    end
    fprintf('\n');
end

fprintf('--- SNR proxy: beta-band power relative to the 70-100 Hz band ---\n');
fprintf('A rise after cleaning indicates artifact removed without loss of\n');
fprintf('physiological signal.\n\n');
fprintf('%-24s %12s %12s %10s\n','group','before (dB)','after (dB)','change');
mbeta = fx>=13 & fx<=30; mhf = fx>=70 & fx<=100;
for c = 1:size(cells,1)
    bef = mean(G(c).(sprintf('s%d',STAGE_BEFORE))(mbeta),'omitnan') - ...
          mean(G(c).(sprintf('s%d',STAGE_BEFORE))(mhf),'omitnan');
    aft = mean(G(c).(sprintf('s%d',STAGE_AFTER))(mbeta),'omitnan') - ...
          mean(G(c).(sprintf('s%d',STAGE_AFTER))(mhf),'omitnan');
    fprintf('%-24s %12.2f %12.2f %+10.2f\n', cellLbl{c}, bef, aft, aft-bef);
end

%% ---- Figure -----------------------------------------------------------
fh = figure('Position',[40 40 1180 640],'Visible','off');
allv = [];
for c = 1:size(cells,1)
    allv = [allv, G(c).(sprintf('s%d',STAGE_BEFORE)), ...
                  G(c).(sprintf('s%d',STAGE_AFTER))]; %#ok<AGROW>
end
allv = allv(isfinite(allv)); pad = 0.08*range(allv);
yl = [min(allv)-pad, max(allv)+pad];

for c = 1:size(cells,1)
    subplot(2,4,c); hold on
    plot(fx, G(c).(sprintf('s%d',STAGE_BEFORE)), 'Color',[0.35 0.35 0.35],'LineWidth',1.5);
    plot(fx, G(c).(sprintf('s%d',STAGE_AFTER)),  'Color',[0.80 0.20 0.20],'LineWidth',1.5);
    xlim([0 FMAX]); ylim(yl); grid on; set(gca,'FontSize',8);
    title(cellLbl{c},'FontSize',9);
    if c==1
        ylabel('power (dB)');
        legend({'before cleaning','after cleaning'},'Location','best','FontSize',7);
    end

    subplot(2,4,4+c); hold on
    d = G(c).(sprintf('s%d',STAGE_AFTER)) - G(c).(sprintf('s%d',STAGE_BEFORE));
    plot(fx, d, 'Color',[0.15 0.35 0.75],'LineWidth',1.5);
    plot([0 FMAX],[0 0],'k--','HandleVisibility','off');
    xlim([0 FMAX]); grid on; set(gca,'FontSize',8);
    xlabel('Hz','FontSize',9);
    if c==1; ylabel('after - before (dB)'); end
end
sgt(sprintf(['Power spectra before (stage %d) and after (stage %d) cleaning, ' ...
    'anodal electrode, n=%d'], STAGE_BEFORE, STAGE_AFTER, nOK));
savefig_both(fh, fullfile(OUT_DIR,'fig_cleaning_psd.png'));

fprintf('\nWrote %s\n', OUT_DIR);

end

% =========================================================================
function sgt(txt)
if exist('sgtitle','file'); sgtitle(txt,'FontSize',10);
else
    annotation('textbox',[0 0.95 1 0.05],'String',txt,'EdgeColor','none', ...
        'HorizontalAlignment','center','FontWeight','bold');
end
end

function savefig_both(fh, pngpath)
print(fh, pngpath, '-dpng','-r150');
[d,n,~] = fileparts(pngpath);
try
    print(fh, fullfile(d,[n '.svg']), '-dsvg','-painters');
catch
end
close(fh);
end
