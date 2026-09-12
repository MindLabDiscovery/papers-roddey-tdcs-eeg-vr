%% run_erd_timeresolved.m
%
% PURPOSE
%   Proper event-related desynchronization (ERD) analysis: time-resolved
%   and baseline-normalized, replacing the absolute-power-per-phase
%   comparison in run_prestim_phase_validation.m.
%
% WHY THE PREVIOUS APPROACH DID NOT WORK
%   1. No rest condition. HOLD is ACTIVE postural maintenance (holding the
%      controller steady inside the start sphere against gravity), and PREP
%      is also active holding. Classical beta ERD is rest -> move; this task
%      is hold -> hold -> reach, so a near-null absolute beta difference is
%      the expected result rather than a recording failure.
%   2. Unequal windows. HOLD 2-6 s, PREP 2-6 s, MOVE ~1 s (movementDuration
%      runs 0.8-1.3 s). Absolute band power over windows differing 3-6x is
%      confounded by window length alone.
%   3. The vibratory cue. A 100 ms, 120 Hz handgrip vibration sits exactly
%      at the HOLD/PREP boundary. Its sharp on/off edges leak broadband
%      power into 1-50 Hz, which is why the previous run showed PREP
%      elevated in alpha AND beta AND gamma simultaneously, in every cell
%      including sham. This script excludes the cue region from baseline.
%
% WHAT THIS DOES INSTEAD
%   ERD% = 100 * (P(t) - P_base) / P_base, on LINEAR power (the standard
%   definition; dB input is converted back before normalizing). Baseline is
%   an early window WITHIN hold, away from both the trial start and the
%   vibratory cue. Every phase is then expressed relative to that common
%   baseline, so unequal phase durations no longer bias the comparison.
%
%   Negative ERD% = desynchronization (power drop). Beta should go NEGATIVE
%   around reach.
%
% DATA
%   power.data : freq x time x chan x phase x trial
%   phase 1=hold 2=prep 3=move ; trial 1=BL 2=ES 3=LS 4=Post
%   Each phase carries its own 60 time bins, so the time axis is treated as
%   within-phase and the three phases are concatenated for display with
%   boundaries marked. Bin index, not seconds, is the x-axis.
%
% OUTPUT
%   console summary
%   erd_timeresolved.csv
%   fig_erd_tf_<cell>.png      time-frequency ERD maps, anode vs homolog
%   fig_erd_band_<band>.png    band time courses, per subject + mean
%
% R2019b safe.

clear; clc; close all;

%% ============================ CONFIG ============================
MAT_PATH = 'C:\Users\ncr200\Downloads\data_raw\subjectData.mat';
OUT_DIR  = fullfile(pwd,'erd_out');
if ~exist(OUT_DIR,'dir'); mkdir(OUT_DIR); end

TRIAL = 1;              % 1=BL (pre-stim). Set 2/3 for ES/LS later.
TRIAL_NAME = 'BL';

% Baseline window inside HOLD, as a fraction of hold's time bins.
% Starts after 15% to avoid the trial-onset edge, ends at 60% to stay well
% clear of the vibratory cue at the end of hold.
BASE_FRAC = [0.15 0.60];

bands = { 'alpha',[8 13]; 'beta',[13 30]; 'lowbeta',[13 20]; ...
          'highbeta',[20 30]; 'band2545',[25 45] };
PLOT_BANDS = {'beta','band2545'};

roster = { '0003','0004','0005','0013','0015','0017','0018','0021','0042','0043', ...
           '0020','0022','0023','0024','0025','0026','0027','0028','0029','0036' };
crf_active = {'0003','0004','0005','0042','0043','0022','0024','0025','0026','0029'};
cells = {'CS','active';'CS','sham';'HC','active';'HC','sham'};

%% ============================ LOAD ==============================
if ~isfile(MAT_PATH); error('Not found: %s',MAT_PATH); end
S = load(MAT_PATH); sd = S.subjectData; sd_names = {sd.SubjectName};

p1 = sd(1).power;
chanlabels = cell(1,numel(p1.chans));
for c = 1:numel(p1.chans)
    if isfield(p1.chans(c),'labels');    chanlabels{c}=p1.chans(c).labels;
    elseif isfield(p1.chans(c),'label'); chanlabels{c}=p1.chans(c).label;
    else;                                chanlabels{c}=sprintf('ch%d',c); end
end
vals = p1.data(:); vals = vals(isfinite(vals));
IS_DB = mean(vals<0) > 0.01;
nT = size(p1.data,2);
fprintf('Units: %s | %d time bins per phase\n', ...
    tern(IS_DB,'dB (converted to linear for ERD)','linear'), nT);

bidx = max(1,round(BASE_FRAC(1)*nT)) : max(2,round(BASE_FRAC(2)*nT));
fprintf('Baseline = HOLD bins %d-%d of %d\n\n', bidx(1), bidx(end), nT);

%% ==================== PER-SUBJECT ERD ==========================
R = struct(); n = 0;
for i = 1:numel(roster)
    sid = roster{i};
    mi = find(contains(sd_names,sid),1);
    if isempty(mi); continue; end
    si = sd(mi).sessioninfo;
    cond = 'sham'; if any(strcmp(sid,crf_active)); cond='active'; end
    grp = 'HC';
    if isstruct(si)&&isfield(si,'dx')&&~isempty(si.dx)&& ...
       strcmpi(strtrim(char(string(si.dx))),'stroke'); grp='CS'; end
    sl = upper(strtrim(char(string(si.stimlat))));
    anode = tern(strcmp(sl,'L'),'C3','C4');
    homol = tern(strcmp(anode,'C3'),'C4','C3');

    ia = find(strcmpi(chanlabels,anode),1);
    ih = find(strcmpi(chanlabels,homol),1);
    if isempty(ia)||isempty(ih); warning('%s: channels missing',sid); continue; end
    f = squeeze(sd(mi).power.freq(1,:,ia));

    n = n + 1;
    R(n).sid=sid; R(n).grp=grp; R(n).cond=cond;
    R(n).anode=anode; R(n).homol=homol; R(n).f=f;

    for role = 1:2
        ci = tern(role==1, ia, ih);

        % linear power, freq x time, for each phase
        P = cell(1,3);
        for ph = 1:3
            raw = squeeze(sd(mi).power.data(:,:,ci,ph,TRIAL));
            if IS_DB; raw = 10.^(raw/10); end   % dB -> linear for ERD
            P{ph} = raw;
        end

        base = mean(P{1}(:,bidx), 2, 'omitnan');       % freq x 1, from HOLD
        erd = [];
        for ph = 1:3
            e = 100 * (P{ph} - base) ./ base;          % ERD% , freq x time
            erd = [erd, e]; %#ok<AGROW>
        end

        if role==1; R(n).erdA = erd; else; R(n).erdH = erd; end
    end
end
R = R(1:n);
fprintf('Processed %d subjects.\n', n);

nTot = size(R(1).erdA,2);
ph_edges = [nT, 2*nT];      % boundaries between hold|prep|move

%% ==================== BAND TIME COURSES =========================
f = R(1).f;
bandTC = struct();
for b = 1:size(bands,1)
    m = f>=bands{b,2}(1) & f<=bands{b,2}(2);
    A = nan(n,nTot); H = nan(n,nTot);
    for k = 1:n
        A(k,:) = mean(R(k).erdA(m,:),1,'omitnan');
        H(k,:) = mean(R(k).erdH(m,:),1,'omitnan');
    end
    bandTC.(bands{b,1}).A = A;
    bandTC.(bands{b,1}).H = H;
end

%% ==================== CONSOLE SUMMARY ==========================
mv = (2*nT+1):nTot;      % MOVE bins
pr = (nT+1):(2*nT);      % PREP bins

fprintf('\n===== ERD%% during MOVE, relative to HOLD baseline (%s) =====\n', TRIAL_NAME);
fprintf('Negative = desynchronization (expected for beta around reach)\n\n');
for b = 1:size(bands,1)
    bn = bands{b,1};
    fprintf('--- %s (%g-%g Hz) ---\n', bn, bands{b,2}(1), bands{b,2}(2));
    fprintf('%-14s %-8s %10s %10s %12s\n','cell','chan','move ERD%','prep ERD%','n negative');
    for c = 1:size(cells,1)
        idx = find(strcmp({R.grp},cells{c,1}) & strcmp({R.cond},cells{c,2}));
        if isempty(idx); continue; end
        for role = {'A','H'}
            M = bandTC.(bn).(role{1})(idx,:);
            mvv = mean(M(:,mv),2,'omitnan');
            prv = mean(M(:,pr),2,'omitnan');
            fprintf('%-14s %-8s %10.2f %10.2f %8d/%d\n', ...
                [cells{c,1} ' ' cells{c,2}], tern(strcmp(role{1},'A'),'anode','homolog'), ...
                mean(mvv,'omitnan'), mean(prv,'omitnan'), sum(mvv<0), numel(mvv));
        end
    end
    fprintf('\n');
end

fprintf('===== HEADLINE: beta ERD during MOVE, all subjects, anode =====\n');
bm = mean(bandTC.beta.A(:,mv),2,'omitnan');
fprintf('mean %+0.2f%%  |  %d/%d subjects negative\n', mean(bm,'omitnan'), sum(bm<0), numel(bm));
fprintf(['If most subjects are negative, beta ERD is present and the montage\n' ...
         'records movement-related physiology. This is the test the previous\n' ...
         'absolute-power comparison could not perform.\n']);

%% ==================== CSV ======================================
rows = {};
for k = 1:n
    for b = 1:size(bands,1)
        bn = bands{b,1};
        rows(end+1,:) = { R(k).sid, R(k).grp, R(k).cond, bn, ...
            mean(bandTC.(bn).A(k,mv),'omitnan'), mean(bandTC.(bn).H(k,mv),'omitnan'), ...
            mean(bandTC.(bn).A(k,pr),'omitnan'), mean(bandTC.(bn).H(k,pr),'omitnan') }; %#ok<AGROW>
    end
end
writetable(cell2table(rows,'VariableNames', ...
    {'SubjectID','Group','Condition','Band','move_anode','move_homolog', ...
     'prep_anode','prep_homolog'}), fullfile(OUT_DIR,'erd_timeresolved.csv'));

%% ==================== FIGURES: TF MAPS =========================
for c = 1:size(cells,1)
    idx = find(strcmp({R.grp},cells{c,1}) & strcmp({R.cond},cells{c,2}));
    if isempty(idx); continue; end
    MA = zeros(size(R(idx(1)).erdA)); MH = MA;
    for k = idx; MA = MA + R(k).erdA; MH = MH + R(k).erdH; end
    MA = MA/numel(idx); MH = MH/numel(idx);
    cl = max([maxabs(MA(:)), maxabs(MH(:))]);
    cl = min(cl, 150);   % cap so a few extreme bins don't wash out the map

    fh = figure('Position',[60 60 1050 400],'Visible','off');
    subplot(1,2,1); imagesc(1:nTot,f,MA); axis xy; caxis([-cl cl]);
    hold on; for e = ph_edges; plot([e e],ylim,'k-','LineWidth',1.2); end
    xlabel('bin  (hold | prep | move)'); ylabel('Hz'); colorbar;
    title(sprintf('%s %s  ANODE  ERD%% (n=%d)',cells{c,1},cells{c,2},numel(idx)));

    subplot(1,2,2); imagesc(1:nTot,f,MH); axis xy; caxis([-cl cl]);
    hold on; for e = ph_edges; plot([e e],ylim,'k-','LineWidth',1.2); end
    xlabel('bin  (hold | prep | move)'); colorbar;
    title('HOMOLOG  ERD%');

    print(fh,fullfile(OUT_DIR,sprintf('fig_erd_tf_%s_%s.png',cells{c,1},cells{c,2})), ...
        '-dpng','-r150'); close(fh);
end

%% ==================== FIGURES: BAND TIME COURSES ===============
for bb = 1:numel(PLOT_BANDS)
    bn = PLOT_BANDS{bb};
    fh = figure('Position',[60 60 1180 560],'Visible','off');
    yl = 0;
    for c = 1:size(cells,1)
        idx = find(strcmp({R.grp},cells{c,1}) & strcmp({R.cond},cells{c,2}));
        if isempty(idx); continue; end
        yl = max([yl, maxabs(bandTC.(bn).A(idx,:)), maxabs(bandTC.(bn).H(idx,:))]);
    end
    yl = min(yl,200);
    for c = 1:size(cells,1)
        idx = find(strcmp({R.grp},cells{c,1}) & strcmp({R.cond},cells{c,2}));
        if isempty(idx); continue; end
        for role = 1:2
            rl = tern(role==1,'A','H');
            subplot(2,4,(role-1)*4+c); hold on;
            M = bandTC.(bn).(rl)(idx,:);
            for k = 1:size(M,1); plot(1:nTot,M(k,:),'Color',[0.65 0.65 0.65]); end
            plot(1:nTot,mean(M,1,'omitnan'),'Color',[0.8 0 0],'LineWidth',2);
            plot(xlim,[0 0],'k--');
            for e = ph_edges; plot([e e],[-yl yl],'k-'); end
            ylim([-yl yl]); xlim([1 nTot]); grid on;
            if c==1; ylabel(sprintf('%s\n%s ERD%%',tern(role==1,'anode','homolog'),bn)); end
            if role==1; title(sprintf('%s %s',cells{c,1},cells{c,2})); end
            if role==2; xlabel('hold | prep | move'); end
        end
    end
    print(fh,fullfile(OUT_DIR,sprintf('fig_erd_band_%s.png',bn)),'-dpng','-r150');
    close(fh);
end

fprintf('\nWrote %s\n',OUT_DIR);
fprintf('Open fig_erd_band_beta.png first: red mean line should dip BELOW 0 in the move segment.\n');

%% ==================== LOCAL FUNCTIONS ==========================
function v = maxabs(x)
x = x(isfinite(x));
v = max(abs(x));
if isempty(v)||v==0; v=1; end
end

function out = tern(c,a,b)
if c; out=a; else; out=b; end
end
