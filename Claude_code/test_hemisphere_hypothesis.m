%% test_hemisphere_hypothesis.m
%
% HYPOTHESIS UNDER TEST
%   Active and sham stimulation do NOT differ when power is measured within
%   a single hemisphere (ipsilesional alone, or contralesional alone), but
%   DO differ when the two hemispheres are compared. If true, the effect is
%   a redistribution between hemispheres rather than a change in local
%   amplitude, and interhemispheric measures are the appropriate readout.
%
%   This has not previously been tested: Figure 4A plots ipsi and contra
%   separately but never compares active against sham within a hemisphere,
%   and the ES-LS analyses used a single electrode.
%
% WHAT IS COMPUTED
%   For every group, phase, block and band, three quantities:
%       IPSI    - mean power across ipsilesional electrodes
%       CONTRA  - mean power across contralesional electrodes
%       DIFF    - ipsi minus contra
%   Then, within the chronic stroke group, active is compared against sham
%   on each of the three. The hypothesis predicts null results on IPSI and
%   CONTRA and a difference on DIFF.
%
%   Reviewer 1 asked that healthy controls not be interpreted biologically
%   alongside the stroke group, so the statistical comparison is
%   within-stroke. Healthy values are reported for reference only.
%
% ELECTRODE SETS
%   'pairs9' - the 9 clean homologous pairs (Fz, Cz, Pz excluded; they were
%              double-counted in the original arrays). Matches Figure 4A.
%   'c3c4'   - C3/C4 only. Matches Figure 4B and the coherence analysis.
%   Both are computed, since 4A and 4B use different sets and the
%   hypothesis should hold for either if it holds at all.
%
% OUTPUT
%   hemisphere_hypothesis.csv     per-subject values, every combination
%   hemisphere_tests.csv          active-vs-sham tests
%   fig_hemisphere_<set>.png      ipsi / contra / diff across blocks
%   console: the three-way comparison that answers the hypothesis
%
% R2019b safe.

clear; clc; close all;

%% ============================ CONFIG ============================
MAT_PATH = 'C:\Users\ncr200\Downloads\data_raw\subjectData.mat';
OUT_DIR  = fullfile(pwd,'hemisphere_out');
if ~exist(OUT_DIR,'dir'); mkdir(OUT_DIR); end

TIME_BINS = 9:60;
phases   = {'Hold','Prep','Reach'};
blockLbl = {'BL','ES','LS','Post'};

bands = { 'delta',[1 4]; 'theta',[4 8]; 'alpha',[8 13]; ...
          'beta',[13 30]; 'gamma',[30 50]; 'broad',[8 25] };

% 9 clean homologous pairs; midline removed
pairsR = [12 13 17 20 14 18 15 19 16];
pairsL = [ 1  2  6  9  3  7  4  8  5];
IDX_C3C4 = 6;

SETS = {'pairs9','c3c4'};

roster = { '0003','0004','0005','0013','0015','0017','0018','0021','0042','0043', ...
           '0020','0022','0023','0024','0025','0026','0027','0028','0029','0036' };
crf_active = {'0003','0004','0005','0042','0043','0022','0024','0025','0026','0029'};
cells = {'CS','stim';'CS','sham';'HC','stim';'HC','sham'};

%% ============================ LOAD ==============================
if ~isfile(MAT_PATH); error('Not found: %s',MAT_PATH); end
S = load(MAT_PATH); sd = S.subjectData; sd_names = {sd.SubjectName};
p1 = sd(1).power;
fvec = squeeze(p1.freq(1,:,1));
fprintf('freq axis: %.2f to %.2f Hz, %d bins, spacing %.3f Hz\n\n', ...
    min(fvec), max(fvec), numel(fvec), median(diff(fvec)));
vals = p1.data(:); vals = vals(isfinite(vals));
IS_DB = mean(vals<0) > 0.01;

%% ==================== EXTRACT ==================================
rows = {};
for i = 1:numel(roster)
    sid = roster{i};
    mi = find(contains(sd_names,sid),1);
    if isempty(mi); continue; end
    si = sd(mi).sessioninfo;
    cond = 'sham'; if any(strcmp(sid,crf_active)); cond='stim'; end
    grp = 'HC';
    if isstruct(si)&&isfield(si,'dx')&&~isempty(si.dx)&& ...
       strcmpi(strtrim(char(string(si.dx))),'stroke'); grp='CS'; end
    sl = upper(strtrim(char(string(si.stimlat))));
    if strcmp(sl,'R'); eI = pairsR; eC = pairsL; else; eI = pairsL; eC = pairsR; end

    for st = 1:numel(SETS)
        if strcmp(SETS{st},'c3c4')
            useI = eI(IDX_C3C4); useC = eC(IDX_C3C4);
        else
            useI = eI; useC = eC;
        end
        for b = 1:size(bands,1)
            fm = fvec>=bands{b,2}(1) & fvec<=bands{b,2}(2);
            for p = 1:3
                for t = 1:4
                    vi = []; vc = [];
                    for e = useI
                        x = sd(mi).power.data(fm,TIME_BINS,e,p,t);
                        if ~IS_DB; x = 10*log10(x); end
                        vi(end+1) = mean(x(:),'omitnan'); %#ok<AGROW>
                    end
                    for e = useC
                        x = sd(mi).power.data(fm,TIME_BINS,e,p,t);
                        if ~IS_DB; x = 10*log10(x); end
                        vc(end+1) = mean(x(:),'omitnan'); %#ok<AGROW>
                    end
                    I = mean(vi,'omitnan'); C = mean(vc,'omitnan');
                    rows(end+1,:) = {sid,grp,cond,SETS{st},bands{b,1}, ...
                        phases{p},blockLbl{t},I,C,I-C}; %#ok<AGROW>
                end
            end
        end
    end
end
T = cell2table(rows,'VariableNames', ...
    {'SubjectID','Group','Condition','ElecSet','Band','Phase','Block', ...
     'ipsi','contra','diff'});
writetable(T, fullfile(OUT_DIR,'hemisphere_hypothesis.csv'));
fprintf('Extracted %d rows.\n\n', height(T));

%% ==================== THE TEST =================================
% Within chronic stroke: active vs sham, on ipsi / contra / diff.
fprintf('================================================================\n');
fprintf('  CHRONIC STROKE: ACTIVE vs SHAM\n');
fprintf('  tested three ways at each block\n');
fprintf('================================================================\n');
fprintf('Hypothesis: null on IPSI and CONTRA, difference on DIFF.\n');
fprintf('n = 5 per condition; treat p-values as descriptive.\n\n');

tr = {};
for st = 1:numel(SETS)
    for b = 1:size(bands,1)
        fprintf('--- %s | %s ---\n', SETS{st}, bands{b,1});
        fprintf('%-6s %-6s %22s %22s %22s\n','phase','block', ...
            'IPSI (act-sham, p)','CONTRA (act-sham, p)','DIFF (act-sham, p)');
        for p = 1:3
            for t = 1:4
                base = strcmp(T.ElecSet,SETS{st}) & strcmp(T.Band,bands{b,1}) & ...
                       strcmp(T.Phase,phases{p}) & strcmp(T.Block,blockLbl{t}) & ...
                       strcmp(T.Group,'CS');
                A = T(base & strcmp(T.Condition,'stim'),:);
                H = T(base & strcmp(T.Condition,'sham'),:);
                out = zeros(1,6);
                [out(1),out(2)] = tt2(A.ipsi,   H.ipsi);
                [out(3),out(4)] = tt2(A.contra, H.contra);
                [out(5),out(6)] = tt2(A.diff,   H.diff);
                fprintf('%-6s %-6s   %+8.3f (%6.3f)%s   %+8.3f (%6.3f)%s   %+8.3f (%6.3f)%s\n', ...
                    phases{p}, blockLbl{t}, ...
                    out(1),out(2),star(out(2)), out(3),out(4),star(out(4)), ...
                    out(5),out(6),star(out(6)));
                tr(end+1,:) = {SETS{st},bands{b,1},phases{p},blockLbl{t}, ...
                    out(1),out(2),out(3),out(4),out(5),out(6)}; %#ok<AGROW>
            end
        end
        fprintf('\n');
    end
end
writetable(cell2table(tr,'VariableNames', ...
    {'ElecSet','Band','Phase','Block','ipsi_d','ipsi_p','contra_d','contra_p', ...
     'diff_d','diff_p'}), fullfile(OUT_DIR,'hemisphere_tests.csv'));

%% ==================== VERDICT ==================================
TR = cell2table(tr,'VariableNames', ...
    {'ElecSet','Band','Phase','Block','ipsi_d','ipsi_p','contra_d','contra_p', ...
     'diff_d','diff_p'});
fprintf('================================================================\n');
fprintf('  HIT COUNTS (p < .05), by measure\n');
fprintf('================================================================\n');
fprintf('The hypothesis predicts few hits on IPSI and CONTRA, more on DIFF.\n');
fprintf('Chance expectation is 5%% of tests in every column.\n\n');
fprintf('%-9s %-8s %6s %10s %10s %10s\n','elecset','band','tests','IPSI','CONTRA','DIFF');
for st = 1:numel(SETS)
    for b = 1:size(bands,1)
        m = strcmp(TR.ElecSet,SETS{st}) & strcmp(TR.Band,bands{b,1});
        fprintf('%-9s %-8s %6d %10d %10d %10d\n', SETS{st}, bands{b,1}, sum(m), ...
            sum(m & TR.ipsi_p<0.05), sum(m & TR.contra_p<0.05), sum(m & TR.diff_p<0.05));
    end
end
n_tot = height(TR);
fprintf('\nOVERALL: %d tests per column, chance ~%.1f\n', n_tot, 0.05*n_tot);
fprintf('  IPSI   %d hits\n  CONTRA %d hits\n  DIFF   %d hits\n', ...
    sum(TR.ipsi_p<0.05), sum(TR.contra_p<0.05), sum(TR.diff_p<0.05));
fprintf(['\nIf IPSI and CONTRA sit at chance while DIFF exceeds it, the\n' ...
         'hypothesis is supported. If all three are at chance, the sample\n' ...
         'cannot resolve the question. If all three exceed chance, the\n' ...
         'effect is not specifically interhemispheric.\n\n']);

%% ==================== FIGURES ==================================
for st = 1:numel(SETS)
    fh = figure('Position',[40 40 1250 700],'Visible','off');
    bshow = {'alpha','beta','gamma'};
    sp = 0;
    for bb = 1:numel(bshow)
        for meas = 1:3
            mn = {'ipsi','contra','diff'};
            sp = sp + 1;
            subplot(numel(bshow),3,sp); hold on
            for c = 1:2   % CS stim, CS sham only
                v = nan(1,4);
                for t = 1:4
                    m = strcmp(T.ElecSet,SETS{st}) & strcmp(T.Band,bshow{bb}) & ...
                        strcmp(T.Phase,'Reach') & strcmp(T.Block,blockLbl{t}) & ...
                        strcmp(T.Group,cells{c,1}) & strcmp(T.Condition,cells{c,2});
                    v(t) = mean(T.(mn{meas})(m),'omitnan');
                end
                plot(1:4, v, '-o', 'LineWidth',2, 'MarkerFaceColor','auto', ...
                    'Color', tern(c==1,[0.8 0.15 0.15],[0.35 0.35 0.35]));
            end
            if meas==3; plot([0.8 4.2],[0 0],'k:'); end
            set(gca,'XTick',1:4,'XTickLabel',blockLbl); xlim([0.8 4.2]); grid on;
            if sp<=3; title(upper(mn{meas})); end
            if meas==1; ylabel(sprintf('%s (dB)',bshow{bb})); end
            if sp==1; legend({'CS stim','CS sham'},'Location','best','FontSize',7); end
        end
    end
    sgt(sprintf('Chronic stroke, Reach phase, %s electrodes', SETS{st}));
    print(fh, fullfile(OUT_DIR,sprintf('fig_hemisphere_%s.png',SETS{st})),'-dpng','-r150');
    close(fh);
end

fprintf('Wrote %s\n', OUT_DIR);

%% ==================== LOCAL FUNCTIONS =========================
function [d,p] = tt2(a,b)
a = a(isfinite(a)); b = b(isfinite(b));
d = mean(a)-mean(b);
if numel(a)<2 || numel(b)<2; p = NaN; return; end
se = sqrt(var(a)/numel(a) + var(b)/numel(b));
if se==0; p = NaN; return; end
t = d/se;
if exist('ttest2','file')==2
    [~,p] = ttest2(a,b,'Vartype','unequal');
else
    p = 2*(1 - 0.5*(1+erf(abs(t)/sqrt(2))));
end
end

function s = star(p)
if ~isfinite(p); s = ' '; elseif p < 0.05; s = '*'; else; s = ' '; end
end

function sgt(txt)
if exist('sgtitle','file'); sgtitle(txt);
else
    annotation('textbox',[0 0.95 1 0.05],'String',txt,'EdgeColor','none', ...
        'HorizontalAlignment','center','FontWeight','bold');
end
end

function out = tern(c,a,b)
if c; out=a; else; out=b; end
end
