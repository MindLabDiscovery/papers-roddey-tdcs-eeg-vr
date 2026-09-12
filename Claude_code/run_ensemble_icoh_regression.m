%% run_ensemble_icoh_regression.m
%
% PURPOSE
%   Regress kinematics on CORRECTED ENSEMBLE imaginary coherence -- the
%   analysis that has not yet been run. The prior session recomputed the
%   ensemble estimator across all 240 cells but used it only for means
%   comparison (which showed the largest Hold->Prep divergence at EARLY
%   stimulation and Post exceeding LS, contradicting the manuscript's
%   claimed late-stimulation reversal). The 4D-style regression on the
%   corrected values is what this script provides.
%
%   This is NOT the degenerate stored subjectData.iCoh (single-trial,
%   |coherency| = 1 by construction, ~chance-level). Input must be the
%   ensemble output of recompute_coherence_comparison.m.
%
% INPUT
%   <outPrefix>_cells.csv, written directly by
%   recompute_coherence_comparison.m. No modification of that script is
%   needed -- it already exports everything required. Columns used:
%     subject            'pro00087153_0003'  (ID parsed from the suffix)
%     group              'CS' | 'HC'
%     condition          'Stim' | 'Sham'
%     block              'BL' | 'ES' | 'LS' | 'Post'
%     phase              'Hold' | 'Prep' | 'Move'
%     absimag_ensemble   CORRECTED ensemble estimator  <-- used here
%     absimag_pertrial   degenerate estimator          <-- NOT used
%     cell_status        'clean' | 'interpolated'
%   Expected: 20 subjects x 4 blocks x 3 phases = 240 rows.
%
%   BAND: whatever GAMMA was set to in recompute_coherence_comparison.m.
%   It ships as [30 50] to match the Figure 4B caption. For the empirically
%   observed 25-45 Hz band, change GAMMA there and re-run before this.
%
%   kinematics_long.csv from extract_kinematics.m.
%
% DESIGN
%   Timepoints (3): BL | LS-ES | Post
%   Phase states (5): hold, prep, move, hold-prep, prep-move
%   Metrics: all 13. Cells: CS active, CS sham, HC active, HC sham.
%   Kinematics matched to timepoint: absolute at BL and Post, LS-ES change
%   for the change timepoint.
%
% ELIGIBILITY
%   EXCLUDE_INTERPOLATED = true reproduces the prior session's criterion,
%   which left only 3 of 5 CS stim subjects. AT n = 3 THE REGRESSION HAS
%   df = 1: r sits near +/-1 almost regardless of the data and p is not
%   interpretable. Run BOTH settings and compare -- if conclusions differ
%   between n=3 and n=5, neither is telling you anything about biology.
%
% READ THE CALIBRATION FIRST
%   Hit counts per cell against chance expectation. Sham and HC cells are
%   null conditions. When the spectral-power version of this analysis was
%   run, 7 of 10 hits landed in HC sham, including r = +0.929 on
%   maxAcceleration -- the metric of interest, in the cell where nothing
%   can be happening. Individual p-values mean little without that context.
%
% OUTPUT
%   console: calibration, published-claim check, all hits
%   ensemble_icoh_regression.csv
%   fig_icoh_scatter_*.png for |r| >= SCATTER_R_MIN
%
% R2019b safe. No toolboxes required.

clear; clc; close all;

%% ============================ CONFIG ============================
COH_PATH = fullfile(pwd,'coh_comparison_cells.csv');   % from recompute_coherence_comparison.m
KIN_PATH = fullfile(pwd,'kinematics_long.csv');
OUT_DIR  = fullfile(pwd,'ensemble_icoh_out');
if ~exist(OUT_DIR,'dir'); mkdir(OUT_DIR); end

EXCLUDE_INTERPOLATED = true;    % run true AND false, compare
SCATTER_R_MIN = 0.85;

phase_states = { 'hold',[1 0 0]; 'prep',[0 1 0]; 'move',[0 0 1]; ...
                 'hold-prep',[1 -1 0]; 'prep-move',[0 1 -1] };
timepoints   = { 'BL',[1 0 0 0]; 'LSminusES',[0 -1 1 0]; 'Post',[0 0 0 1] };

cells = {'CS','active';'CS','sham';'HC','active';'HC','sham'};
% group/condition are read from the CSV; 'Stim' is mapped to 'active'.

%% ============================ LOAD ==============================
if ~isfile(COH_PATH)
    error(['%s not found.\n' ...
        'Run recompute_coherence_comparison.m first -- it writes this file\n' ...
        'directly. Do NOT substitute subjectData.iCoh (degenerate estimator).'], COH_PATH);
end
C = readtable(COH_PATH,'Delimiter',',');

req = {'subject','group','condition','block','phase','absimag_ensemble','cell_status'};
miss = req(~ismember(req,C.Properties.VariableNames));
if ~isempty(miss)
    error('Missing columns in %s: %s', COH_PATH, strjoin(miss,', '));
end
C.subject = cellstr(string(C.subject));
C.group   = cellstr(string(C.group));
C.condition = cellstr(string(C.condition));
C.block   = cellstr(string(C.block));
C.phase   = cellstr(string(C.phase));
C.cell_status = cellstr(string(C.cell_status));

% parse '0003' out of 'pro00087153_0003'
C.sid = cell(height(C),1);
for i = 1:height(C)
    tok = regexp(C.subject{i},'(\d{4})$','tokens','once');
    if isempty(tok); C.sid{i} = C.subject{i}; else; C.sid{i} = tok{1}; end
end

fprintf('Loaded %d rows, %d subjects.\n', height(C), numel(unique(C.sid)));
if height(C) ~= 240
    warning('Expected 240 rows (20 x 4 x 3), found %d.', height(C));
end

% Confirm we are using the corrected estimator, not the degenerate one.
ve = C.absimag_ensemble(isfinite(C.absimag_ensemble));
fprintf('\n=== ESTIMATOR CHECK ===\n');
fprintf('ensemble : mean %.4f  sd %.4f  range [%.4f %.4f]\n', ...
    mean(ve), std(ve), min(ve), max(ve));
if ismember('absimag_pertrial',C.Properties.VariableNames)
    vp = C.absimag_pertrial(isfinite(C.absimag_pertrial));
    fprintf('per-trial: mean %.4f  sd %.4f   (2/pi = %.4f, chance)\n', ...
        mean(vp), std(vp), 2/pi);
    ok = isfinite(C.absimag_ensemble) & isfinite(C.absimag_pertrial);
    if sum(ok) > 3
        a = C.absimag_ensemble(ok); b = C.absimag_pertrial(ok);
        ac = a-mean(a); bc = b-mean(b);
        fprintf('correlation between estimators: r = %.3f\n', ...
            sum(ac.*bc)/sqrt(sum(ac.^2)*sum(bc.^2)));
    end
end
if abs(mean(ve)-2/pi) < 0.02 && std(ve) < 0.06
    warning('Ensemble column resembles the degenerate signature. Verify the source.');
end

nclean = sum(strcmp(C.cell_status,'clean'));
fprintf('clean cells: %d of %d (%.0f%%)\n\n', nclean, height(C), 100*nclean/height(C));

T = readtable(KIN_PATH,'Delimiter',',');
if ~iscell(T.SubjectID)
    T.SubjectID = arrayfun(@(x)sprintf('%04d',x),T.SubjectID,'UniformOutput',false);
end
T.Block = cellstr(string(T.Block)); T.Metric = cellstr(string(T.Metric));
metrics = unique(T.Metric,'stable');
blocks  = {'BL','ES','LS','Post'};

%% ==================== ASSEMBLE PER SUBJECT =====================
coh = containers.Map(); elig = containers.Map();
kin = containers.Map(); meta = containers.Map();

phaseNames  = {'Hold','Prep','Move'};
blockLabels = {'BL','ES','LS','Post'};

subs = unique(C.sid,'stable');
for i = 1:numel(subs)
    sid = subs{i};
    M = nan(3,4); E = false(3,4);
    for ph = 1:3
        for tr = 1:4
            m = strcmp(C.sid,sid) & strcmp(C.phase,phaseNames{ph}) & ...
                strcmp(C.block,blockLabels{tr});
            if any(m)
                k = find(m,1);
                M(ph,tr) = C.absimag_ensemble(k);
                E(ph,tr) = strcmp(C.cell_status{k},'clean');
            end
        end
    end
    coh(sid) = M; elig(sid) = E;

    k1 = find(strcmp(C.sid,sid),1);
    grp = C.group{k1};
    cond = lower(C.condition{k1});          % 'Stim'/'Sham' -> 'stim'/'sham'
    if strcmp(cond,'stim'); cond = 'active'; end
    meta(sid) = {grp,cond};

    K = nan(numel(metrics),4);
    for mm = 1:numel(metrics)
        for b = 1:4
            vv = T.Value(strcmp(T.SubjectID,sid)&strcmp(T.Metric,metrics{mm})& ...
                         strcmp(T.Block,blockLabels{b}));
            K(mm,b) = mean(vv,'omitnan');
        end
    end
    kin(sid) = K;
end
roster = subs(:)';

%% ==================== REGRESSIONS ==============================
rows = {}; scat = {};
for c = 1:size(cells,1)
    ids = {};
    for i = 1:numel(roster)
        sid = roster{i}; mm = meta(sid);
        if strcmp(mm{1},cells{c,1})&&strcmp(mm{2},cells{c,2}); ids{end+1}=sid; end %#ok<AGROW>
    end

    for tp = 1:size(timepoints,1)
        wT = timepoints{tp,2};
        for ps = 1:size(phase_states,1)
            wP = phase_states{ps,2};

            use = {}; x = [];
            for k = 1:numel(ids)
                M = coh(ids{k}); E = elig(ids{k});
                need = (abs(wP')*abs(wT)) > 0;         % cells this contrast touches
                if EXCLUDE_INTERPOLATED && any(~E(need)); continue; end
                val = wP * M * wT';
                if ~isfinite(val); continue; end
                use{end+1} = ids{k}; x(end+1,1) = val; %#ok<AGROW>
            end
            if numel(use) < 3; continue; end

            for mi = 1:numel(metrics)
                y = nan(numel(use),1);
                for k = 1:numel(use)
                    K = kin(use{k}); y(k) = K(mi,:) * wT';
                end
                g = isfinite(x)&isfinite(y);
                if sum(g) < 3; continue; end
                [r,p] = lin_reg(x(g),y(g));
                rows(end+1,:) = {cells{c,1},cells{c,2},timepoints{tp,1}, ...
                    phase_states{ps,1},metrics{mi},sum(g),r,r^2,p}; %#ok<AGROW>
                if abs(r) >= SCATTER_R_MIN
                    scat{end+1} = {cells{c,1},cells{c,2},timepoints{tp,1}, ...
                        phase_states{ps,1},metrics{mi},x(g),y(g),use(g),r,p}; %#ok<AGROW>
                end
            end
        end
    end
end

Tr = cell2table(rows,'VariableNames', ...
    {'Group','Condition','Timepoint','PhaseState','Metric','n','r','R2','p'});
writetable(Tr, fullfile(OUT_DIR,'ensemble_icoh_regression.csv'));

%% ==================== CALIBRATION ==============================
fprintf('\n================================================================\n');
fprintf('  CALIBRATION -- READ BEFORE ANY INDIVIDUAL p-VALUE\n');
fprintf('  EXCLUDE_INTERPOLATED = %s\n', mat2str(EXCLUDE_INTERPOLATED));
fprintf('================================================================\n\n');
fprintf('%-14s %6s %8s %8s %10s %8s\n','cell','n','tests','p<.05','expected','rate');
for c = 1:size(cells,1)
    m = strcmp(Tr.Group,cells{c,1})&strcmp(Tr.Condition,cells{c,2});
    if ~any(m); continue; end
    fprintf('%-14s %6d %8d %8d %10.1f %7.1f%%\n', ...
        [cells{c,1} ' ' cells{c,2}], max(Tr.n(m)), sum(m), sum(m&Tr.p<0.05), ...
        0.05*sum(m), 100*sum(m&Tr.p<0.05)/sum(m));
end
fprintf('\nTOTAL %d tests, %d hits, %.1f expected by chance\n', ...
    height(Tr), sum(Tr.p<0.05), 0.05*height(Tr));
if any(Tr.n <= 3)
    fprintf(['\n!! Some contrasts ran at n<=3 (df=1). Those r values are near\n' ...
             '   +/-1 by construction and their p-values are not interpretable.\n']);
end

%% ==================== PUBLISHED CLAIM ==========================
fprintf('\n--- Published claim: CS active, hold-prep, late stimulation ---\n');
fprintf('Manuscript: movementDuration p=0.0198 (r2=0.874), velocityPeaks p=0.0188 (r2=0.878)\n');
fprintf('Corrected ensemble estimator, nearest contrast (LSminusES, hold-prep):\n\n');
m = strcmp(Tr.Group,'CS')&strcmp(Tr.Condition,'active')& ...
    strcmp(Tr.PhaseState,'hold-prep')&strcmp(Tr.Timepoint,'LSminusES');
if any(m)
    sub = sortrows(Tr(m,:),'p');
    for i = 1:height(sub)
        star = ''; if sub.p(i)<0.05; star=' *'; end
        fprintf('  %-22s n=%d r=%+.3f R2=%.3f p=%.4f%s\n', ...
            sub.Metric{i},sub.n(i),sub.r(i),sub.R2(i),sub.p(i),star);
    end
else
    fprintf('  No eligible subjects for this contrast at current settings.\n');
end

%% ==================== HITS =====================================
fprintf('\n--- All hits p<.05 (note which cells) ---\n');
h = sortrows(Tr(Tr.p<0.05,:),'p');
for i = 1:height(h)
    fprintf('  %-3s %-7s %-11s %-11s %-20s n=%d r=%+.3f p=%.4f\n', ...
        h.Group{i},h.Condition{i},h.Timepoint{i},h.PhaseState{i}, ...
        h.Metric{i},h.n(i),h.r(i),h.p(i));
end
if isempty(h); fprintf('  none\n'); end

%% ==================== SCATTERS =================================
for s = 1:numel(scat)
    Sc = scat{s};
    fh = figure('Position',[100 100 430 390],'Visible','off');
    plot(Sc{6},Sc{7},'ko','MarkerFaceColor',[0.2 0.4 0.8],'MarkerSize',8); hold on;
    if numel(Sc{6})>2
        pf = polyfit(Sc{6},Sc{7},1);
        xx = linspace(min(Sc{6}),max(Sc{6}),10);
        plot(xx,polyval(pf,xx),'r-','LineWidth',1.3);
    end
    for q=1:numel(Sc{8}); text(Sc{6}(q),Sc{7}(q),['  ' Sc{8}{q}],'FontSize',8); end
    grid on;
    xlabel(sprintf('ensemble iCoh  %s / %s',Sc{3},Sc{4}));
    ylabel(sprintf('%s  %s',Sc{5},Sc{3}));
    title(sprintf('%s %s   r=%+.3f p=%.4f n=%d',Sc{1},Sc{2},Sc{9},Sc{10},numel(Sc{6})), ...
        'FontSize',9);
    print(fh,fullfile(OUT_DIR,sprintf('fig_icoh_scatter_%s_%s_%s_%s_%s.png', ...
        Sc{1},Sc{2},Sc{3},strrep(Sc{4},'-','_'),Sc{5})),'-dpng','-r150');
    close(fh);
end

fprintf('\nWrote %s\n',OUT_DIR);
fprintf('Now re-run with EXCLUDE_INTERPOLATED = %s and compare.\n', ...
    mat2str(~EXCLUDE_INTERPOLATED));

%% ==================== LOCAL FUNCTIONS ==========================
function [r,p] = lin_reg(x,y)
n = numel(x);
xc = x-mean(x); yc = y-mean(y);
den = sqrt(sum(xc.^2)*sum(yc.^2));
if den==0; r=NaN; p=NaN; return; end
r = sum(xc.*yc)/den;
if n>2 && abs(r)<1
    t = r*sqrt((n-2)/(1-r^2));
    if exist('tcdf','file')==2; p = 2*(1-tcdf(abs(t),n-2));
    else; p = 2*(1-0.5*(1+erf(abs(t)/sqrt(2)))); end
elseif abs(r)>=1; p = 0;
else; p = NaN; end
end
