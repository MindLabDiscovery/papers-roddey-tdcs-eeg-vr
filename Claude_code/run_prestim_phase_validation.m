%% run_prestim_phase_validation.m
%
% PURPOSE
%   Physiological sanity check on the recordings themselves, using only
%   PRE-STIMULATION data (trial 1 = BL). No current is flowing, so nothing
%   here can be apparatus artifact.
%
%   Expected, if the montage records real cortical physiology:
%     BETA  (13-30 Hz) -- event-related desynchronization: LOWEST during
%                         move, HIGHER during hold/rest.
%     GAMMA (25-45 Hz) -- generally INCREASES with movement, though this is
%                         less reliable at the scalp than the beta effect.
%
%   This is the strongest statistical footing available in the project:
%   all 20 subjects contribute, and the comparison is WITHIN subject across
%   movement phase, so between-subject variance drops out. If beta ERD is
%   present here, the claim that this montage can record physiology is
%   established independently of anything involving stimulation.
%
% PHASE CODING
%   power.data dim 4: 1 = hold, 2 = prep, 3 = move
%   power.data dim 5: 1 = BL (pre-stim)  <- the only trial used here
%
% CONTRASTS
%   Absolute band power per phase, and the pairwise differences
%   (hold-prep, prep-move, hold-move), since differences sometimes show
%   the effect more clearly than absolute levels.
%
% OUTPUT
%   console tables
%   prestim_phase_bands.csv
%   fig_prestim_<band>.png    per band, all cells, per-subject lines
%
% R2019b safe. No toolboxes required.

clear; clc; close all;

%% ============================ CONFIG ============================
MAT_PATH = 'C:\Users\ncr200\Downloads\data_raw\subjectData.mat';
OUT_DIR  = fullfile(pwd, 'prestim_phase_out');
if ~exist(OUT_DIR,'dir'); mkdir(OUT_DIR); end

TRIAL_BL = 1;
PHASES   = {'hold','prep','move'};

% 25-45 Hz per the observed band in the ES-LS contrast, not a textbook bin.
bands = { 'alpha',[8 13]; 'beta',[13 30]; 'gamma',[25 45]; 'control',[70 100] };

% Channels: anode-side motor and its homolog. Beta ERD should be present at
% both (movement is bilateral-ish at the scalp) but is typically clearer
% contralateral to the moving hand.
USE_CHANS = {'C3','C4'};

roster = { '0003','0004','0005','0013','0015','0017','0018','0021','0042','0043', ...
           '0020','0022','0023','0024','0025','0026','0027','0028','0029','0036' };
crf_active = {'0003','0004','0005','0042','0043','0022','0024','0025','0026','0029'};

%% ============================ LOAD ==============================
if ~isfile(MAT_PATH); error('Not found: %s', MAT_PATH); end
S = load(MAT_PATH); sd = S.subjectData; sd_names = {sd.SubjectName};

p1 = sd(1).power;
chanlabels = cell(1,numel(p1.chans));
for c = 1:numel(p1.chans)
    if isfield(p1.chans(c),'labels');    chanlabels{c} = p1.chans(c).labels;
    elseif isfield(p1.chans(c),'label'); chanlabels{c} = p1.chans(c).label;
    else;                                chanlabels{c} = sprintf('ch%d',c); end
end
vals = p1.data(:); vals = vals(isfinite(vals));
IS_DB = mean(vals<0) > 0.01;
fprintf('Units: %s\n\n', tern(IS_DB,'already dB','linear -> 10*log10'));

%% ==================== EXTRACT ==================================
rows = {};
for i = 1:numel(roster)
    sid = roster{i};
    mi = find(contains(sd_names,sid),1);
    if isempty(mi); warning('%s missing.',sid); continue; end

    cond = 'sham'; if any(strcmp(sid,crf_active)); cond='active'; end
    grp = 'HC';
    si = sd(mi).sessioninfo;
    if isstruct(si) && isfield(si,'dx') && ~isempty(si.dx) && ...
       strcmpi(strtrim(char(string(si.dx))),'stroke'); grp='CS'; end

    sl = upper(strtrim(char(string(si.stimlat))));
    anode = tern(strcmp(sl,'L'),'C3','C4');

    for cc = 1:numel(USE_CHANS)
        ch = USE_CHANS{cc};
        ci = find(strcmpi(chanlabels,ch),1);
        if isempty(ci); continue; end
        f = squeeze(sd(mi).power.freq(1,:,ci));

        role = tern(strcmp(ch,anode),'anode','homolog');

        bp = nan(numel(PHASES), size(bands,1));
        for ph = 1:numel(PHASES)
            psd = mean(get_spec(sd,mi,ci,ph,TRIAL_BL,IS_DB),2,'omitnan');
            for b = 1:size(bands,1)
                m = f>=bands{b,2}(1) & f<=bands{b,2}(2);
                bp(ph,b) = mean(psd(m),'omitnan');
            end
        end

        row = {sid, grp, cond, ch, role};
        for b = 1:size(bands,1)
            row = [row, {bp(1,b), bp(2,b), bp(3,b), ...
                         bp(1,b)-bp(2,b), bp(2,b)-bp(3,b), bp(1,b)-bp(3,b)}]; %#ok<AGROW>
        end
        rows(end+1,:) = row; %#ok<AGROW>
    end
end

vn = {'SubjectID','Group','Condition','Chan','Role'};
for b = 1:size(bands,1)
    n = bands{b,1};
    vn = [vn, {[n '_hold'],[n '_prep'],[n '_move'], ...
               [n '_hold_minus_prep'],[n '_prep_minus_move'],[n '_hold_minus_move']}]; %#ok<AGROW>
end
T = cell2table(rows,'VariableNames',vn);
writetable(T, fullfile(OUT_DIR,'prestim_phase_bands.csv'));

%% ==================== CONSOLE SUMMARY ==========================
fprintf('===== PRE-STIM BAND POWER BY MOVEMENT PHASE (trial 1, no current) =====\n\n');
cells = {'CS','active';'CS','sham';'HC','active';'HC','sham'};

for b = 1:size(bands,1)
    nm = bands{b,1};
    fprintf('--- %s (%g-%g Hz) ---\n', nm, bands{b,2}(1), bands{b,2}(2));
    fprintf('%-14s %-8s %8s %8s %8s %12s %12s\n', ...
        'cell','chan','hold','prep','move','hold-move','n same sign');
    for c = 1:size(cells,1)
        for r = {'anode','homolog'}
            m = strcmp(T.Group,cells{c,1}) & strcmp(T.Condition,cells{c,2}) & ...
                strcmp(T.Role,r{1});
            if ~any(m); continue; end
            hm = T.([nm '_hold_minus_move'])(m);
            mu = mean(hm,'omitnan');
            fprintf('%-14s %-8s %8.3f %8.3f %8.3f %12.3f %8d/%d\n', ...
                [cells{c,1} ' ' cells{c,2}], r{1}, ...
                mean(T.([nm '_hold'])(m),'omitnan'), ...
                mean(T.([nm '_prep'])(m),'omitnan'), ...
                mean(T.([nm '_move'])(m),'omitnan'), ...
                mu, sum(sign(hm)==sign(mu)), numel(hm));
        end
    end
    fprintf('\n');
end

% The headline test: beta hold-move across ALL subjects, both channels.
fprintf('===== HEADLINE: beta ERD, all subjects pooled =====\n');
hm_all = T.beta_hold_minus_move;
hm_all = hm_all(isfinite(hm_all));
[p,tst] = ttest1_safe(hm_all);
fprintf('beta (hold - move): mean %+0.3f dB, n=%d, t=%+0.3f, p=%.5f\n', ...
    mean(hm_all), numel(hm_all), tst, p);
fprintf('%d/%d observations positive (beta lower during move = ERD present)\n', ...
    sum(hm_all>0), numel(hm_all));
gm_all = T.gamma_hold_minus_move; gm_all = gm_all(isfinite(gm_all));
[pg,tg] = ttest1_safe(gm_all);
fprintf('gamma(hold - move): mean %+0.3f dB, n=%d, t=%+0.3f, p=%.5f\n', ...
    mean(gm_all), numel(gm_all), tg, pg);
fprintf('  (expect NEGATIVE for gamma if it increases with movement)\n');
fprintf(['\nNOTE: observations are not independent (2 channels per subject).\n' ...
         'Treat these p-values as descriptive; the per-subject sign counts\n' ...
         'above are the more honest summary.\n']);

%% ==================== FIGURES ==================================
for b = 1:size(bands,1)
    nm = bands{b,1};
    fh = figure('Position',[60 60 1150 560],'Visible','off');
    for c = 1:size(cells,1)
        for ri = 1:2
            role = tern(ri==1,'anode','homolog');
            subplot(2,4,(ri-1)*4 + c); hold on;
            m = find(strcmp(T.Group,cells{c,1}) & strcmp(T.Condition,cells{c,2}) & ...
                     strcmp(T.Role,role));
            Y = [T.([nm '_hold'])(m), T.([nm '_prep'])(m), T.([nm '_move'])(m)];
            for s = 1:size(Y,1)
                plot(1:3, Y(s,:), '-o', 'Color',[0.6 0.6 0.6], 'MarkerSize',3);
            end
            plot(1:3, mean(Y,1,'omitnan'), '-o','Color',[0.8 0 0], ...
                'LineWidth',2,'MarkerFaceColor',[0.8 0 0]);
            set(gca,'XTick',1:3,'XTickLabel',PHASES); xlim([0.7 3.3]); grid on;
            if c==1; ylabel(sprintf('%s\n%s (dB)', role, nm)); end
            if ri==1; title(sprintf('%s %s', cells{c,1}, cells{c,2})); end
        end
    end
    print(fh, fullfile(OUT_DIR,sprintf('fig_prestim_%s.png',nm)),'-dpng','-r150');
    close(fh);
end
fprintf('\nWrote %s\n', OUT_DIR);
fprintf('Look at fig_prestim_beta.png first: move should sit BELOW hold.\n');

%% ==================== LOCAL FUNCTIONS ==========================
function sg = get_spec(sd, sidx, ch, phase, trial, is_db)
raw = squeeze(sd(sidx).power.data(:,:,ch,phase,trial));
if is_db; sg = raw; else; sg = 10*log10(raw); end
end

function [p,tstat] = ttest1_safe(d)
d = d(~isnan(d)); n = numel(d);
if n < 2; p=NaN; tstat=NaN; return; end
tstat = mean(d)/(std(d)/sqrt(n));
if exist('ttest','file')==2
    [~,p] = ttest(d);
else
    p = 2*(1-0.5*(1+erf(abs(tstat)/sqrt(2))));
end
end

function out = tern(c,a,b)
if c; out=a; else; out=b; end
end
