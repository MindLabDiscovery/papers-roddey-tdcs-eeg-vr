%% fig4b_bands_cs_stim_vs_sham_v01.m
%
% PURPOSE
%   Replacement Figure 4B. Asks a single question: does spectral power
%   differ between chronic stroke active and sham stimulation, resolved by
%   frequency band, timepoint and movement phase?
%
%   This complements rather than decomposes Figure 4A. 4A is descriptive
%   and shows how power behaves across all four groups and both
%   hemispheres. 4B is inferential and restricted to the within-stroke
%   active-versus-sham contrast, which is the comparison Reviewer 1's
%   critique of the healthy-control role leaves available.
%
% WHY THIS REPLACES THE PUBLISHED 4B
%   The published panel compared CS stim against HC stim — the cross-group
%   comparison the reviewer objected to. It also used C3-C4 only, applied
%   an absolute value that destroyed the sign of the difference (the source
%   of the uniformly positive values noted in Supplementary Table 1),
%   rounded to integers for the polar histogram, and reported no
%   statistics.
%
% TIMEPOINTS
%   pre    - baseline, absolute
%   LS-ES  - late minus early stimulation, a difference
%   post   - post-stimulation, absolute
%   Chosen to match the coherence figure. Each panel holds one timepoint,
%   so the absolute/difference distinction does not mix within an axis.
%
% MEASURE (set MEASURE below)
%   'diff'   - ipsi minus contra. The default: this is the power analogue
%              of the interhemispheric C3-C4 coherence measure.
%   'ipsi'   - ipsilesional hemisphere alone
%   'contra' - contralesional hemisphere alone
%   All three are reported in the console regardless of which is plotted.
%
% EXPECTATION
%   A null result is the likely and acceptable outcome. Prior testing found
%   no active-versus-sham difference on the interhemispheric measure at any
%   band or block. The one exception was delta-band power at the anodal
%   electrode during stimulation, which matches the drift artifact in both
%   magnitude and timing and is not interpreted as physiology.
%
% OUTPUT
%   fig4b_bands.png            9 panels: 3 phases x 3 timepoints
%   fig4b_bands_values.csv     per-subject values
%   fig4b_bands_stats.csv      tests, raw and FDR-corrected
%
% R2019b safe. No toolboxes required.

clear; clc; close all;

%% ============================ CONFIG ============================
MAT_PATH = 'C:\Users\ncr200\Downloads\data_raw\subjectData.mat';
OUT_DIR  = fullfile(pwd,'fig4b_out');
if ~exist(OUT_DIR,'dir'); mkdir(OUT_DIR); end

MEASURE   = 'diff';      % 'diff' | 'ipsi' | 'contra'
ELEC_SET  = 'pairs9';    % 'pairs9' (matches 4A) | 'c3c4' (matches coherence)
SHOW_PTS  = true;        % overlay individual subjects on the bars

TIME_BINS = 9:60;
phases    = {'Hold','Prep','Reach'};
blockLbl  = {'BL','ES','LS','Post'};
tpLbl     = {'pre','LS-ES','post'};

bands = { 'delta',[1 4]; 'theta',[4 8]; 'alpha',[8 13]; ...
          'beta',[13 30]; 'gamma',[30 50] };

pairsR = [12 13 17 20 14 18 15 19 16];   % Fp2 F8 F4 A2 T4 C4 T6 P4 O2
pairsL = [ 1  2  6  9  3  7  4  8  5];   % Fp1 F7 F3 A1 T3 C3 T5 P3 O1
IDX_C3C4 = 6;

cs_all     = {'0003','0004','0005','0013','0015','0017','0018','0021','0042','0043'};
crf_active = {'0003','0004','0005','0042','0043','0022','0024','0025','0026','0029'};

%% ============================ LOAD ==============================
if ~isfile(MAT_PATH); error('Not found: %s',MAT_PATH); end
S = load(MAT_PATH); sd = S.subjectData; sd_names = {sd.SubjectName};
p1 = sd(1).power; fvec = squeeze(p1.freq(1,:,1));
vals = p1.data(:); vals = vals(isfinite(vals));
IS_DB = mean(vals<0) > 0.01;
fprintf('freq axis %.2f-%.2f Hz | units: %s\n', min(fvec), max(fvec), ...
    tern(IS_DB,'dB','linear->dB'));

%% ==================== EXTRACT ==================================
% V.(cond)(subject, band, phase, timepoint) for the chosen measure
sids = struct('stim',{{}},'sham',{{}});
raw  = struct();   % raw.(cond).(meas)(subj,band,phase,block)

for i = 1:numel(cs_all)
    sid = cs_all{i};
    mi = find(contains(sd_names,sid),1);
    if isempty(mi); warning('%s missing',sid); continue; end
    cond = 'sham'; if any(strcmp(sid,crf_active)); cond='stim'; end
    sl = upper(strtrim(char(string(sd(mi).sessioninfo.stimlat))));
    if strcmp(sl,'R'); eI = pairsR; eC = pairsL; else; eI = pairsL; eC = pairsR; end
    if strcmp(ELEC_SET,'c3c4'); eI = eI(IDX_C3C4); eC = eC(IDX_C3C4); end

    sids.(cond){end+1} = sid;
    k = numel(sids.(cond));
    for b = 1:size(bands,1)
        fm = fvec>=bands{b,2}(1) & fvec<=bands{b,2}(2);
        for p = 1:3
            for t = 1:4
                gi = zeros(1,numel(eI)); gc = zeros(1,numel(eC));
                for e = 1:numel(eI)
                    x = sd(mi).power.data(fm,TIME_BINS,eI(e),p,t);
                    if ~IS_DB; x = 10*log10(x); end
                    gi(e) = mean(x(:),'omitnan');
                end
                for e = 1:numel(eC)
                    x = sd(mi).power.data(fm,TIME_BINS,eC(e),p,t);
                    if ~IS_DB; x = 10*log10(x); end
                    gc(e) = mean(x(:),'omitnan');
                end
                raw.(cond).ipsi(k,b,p,t)   = mean(gi,'omitnan');
                raw.(cond).contra(k,b,p,t) = mean(gc,'omitnan');
                raw.(cond).diff(k,b,p,t)   = mean(gi,'omitnan') - mean(gc,'omitnan');
            end
        end
    end
end
fprintf('CS stim n=%d, CS sham n=%d\n\n', numel(sids.stim), numel(sids.sham));

% (blocks are collapsed to the three timepoints by tps(), defined at the end)

%% ==================== STATS ====================================
meas_all = {'ipsi','contra','diff'};
rows = {}; srows = {};
for mi_ = 1:numel(meas_all)
    mname = meas_all{mi_};
    A = tps(raw.stim.(mname));
    H = tps(raw.sham.(mname));
    for b = 1:size(bands,1)
        for p = 1:3
            for t = 1:3
                a = squeeze(A(:,b,p,t)); a = a(isfinite(a));
                h = squeeze(H(:,b,p,t)); h = h(isfinite(h));
                [d,pv] = tt2(a,h);
                srows(end+1,:) = {mname,bands{b,1},phases{p},tpLbl{t}, ...
                    numel(a),numel(h),mean(a),sem(a),mean(h),sem(h),d,pv}; %#ok<AGROW>
            end
        end
    end
    % per-subject values for the plotted measure
    if strcmp(mname,MEASURE)
        for c = {'stim','sham'}
            X = tps(raw.(c{1}).(mname));
            for k = 1:size(X,1)
                for b = 1:size(bands,1)
                    for p = 1:3
                        for t = 1:3
                            rows(end+1,:) = {sids.(c{1}){k},c{1},mname, ...
                                bands{b,1},phases{p},tpLbl{t},X(k,b,p,t)}; %#ok<AGROW>
                        end
                    end
                end
            end
        end
    end
end
ST = cell2table(srows,'VariableNames', ...
    {'Measure','Band','Phase','Timepoint','n_stim','n_sham', ...
     'mean_stim','sem_stim','mean_sham','sem_sham','diff_stim_minus_sham','p'});

% FDR within the plotted measure (45 tests)
sel = strcmp(ST.Measure,MEASURE);
ST.p_FDR = nan(height(ST),1);
ST.p_FDR(sel) = bh_fdr(ST.p(sel));

writetable(ST, fullfile(OUT_DIR,'fig4b_bands_stats.csv'));
writetable(cell2table(rows,'VariableNames', ...
    {'SubjectID','Condition','Measure','Band','Phase','Timepoint','Value'}), ...
    fullfile(OUT_DIR,'fig4b_bands_values.csv'));

%% ==================== CONSOLE ==================================
for mi_ = 1:numel(meas_all)
    mname = meas_all{mi_};
    fprintf('================================================================\n');
    fprintf('  %s  |  CS stim vs CS sham  |  %s electrodes\n', upper(mname), ELEC_SET);
    fprintf('================================================================\n');
    fprintf('%-7s %-7s %-8s %10s %10s %10s %9s\n', ...
        'band','phase','timept','stim','sham','stim-sham','p');
    for b = 1:size(bands,1)
        for p = 1:3
            for t = 1:3
                r = ST(strcmp(ST.Measure,mname)&strcmp(ST.Band,bands{b,1})& ...
                       strcmp(ST.Phase,phases{p})&strcmp(ST.Timepoint,tpLbl{t}),:);
                fprintf('%-7s %-7s %-8s %10.3f %10.3f %+10.3f %9.4f%s\n', ...
                    bands{b,1},phases{p},tpLbl{t}, r.mean_stim, r.mean_sham, ...
                    r.diff_stim_minus_sham, r.p, star(r.p));
            end
        end
    end
    m = strcmp(ST.Measure,mname);
    fprintf('\n  %d of %d tests at p<.05 (chance ~%.1f)\n\n', ...
        sum(m & ST.p<0.05), sum(m), 0.05*sum(m));
end

sel = strcmp(ST.Measure,MEASURE);
fprintf('=== PLOTTED MEASURE (%s): FDR ===\n', MEASURE);
fprintf('  raw p<.05 : %d of %d\n', sum(sel & ST.p<0.05), sum(sel));
fprintf('  FDR q<.05 : %d of %d\n', sum(sel & ST.p_FDR<0.05), sum(sel));
if sum(sel & ST.p_FDR<0.05)==0
    fprintf(['  No band, timepoint or movement phase shows a difference\n' ...
             '  between active and sham that survives correction.\n']);
end

%% ==================== FIGURE ===================================
A = tps(raw.stim.(MEASURE));  H = tps(raw.sham.(MEASURE));
nb = size(bands,1);
fh = figure('Position',[40 40 1250 780],'Visible','off');
sp = 0;
% common y-limits within each timepoint column
ylims = nan(3,2);
for t = 1:3
    v = [reshape(A(:,:,:,t),[],1); reshape(H(:,:,:,t),[],1)];
    v = v(isfinite(v)); pad = 0.15*range(v);
    ylims(t,:) = [min(v)-pad, max(v)+pad];
end
for p = 1:3
    for t = 1:3
        sp = sp+1; subplot(3,3,sp); hold on
        ms = nan(1,nb); ss = nan(1,nb); mh = nan(1,nb); sh = nan(1,nb);
        for b = 1:nb
            a = squeeze(A(:,b,p,t)); h = squeeze(H(:,b,p,t));
            ms(b)=mean(a,'omitnan'); ss(b)=sem(a);
            mh(b)=mean(h,'omitnan'); sh(b)=sem(h);
        end
        hb = bar((1:nb)', [ms; mh]', 'grouped');
        set(hb(1),'FaceColor',[0.80 0.20 0.20]);
        set(hb(2),'FaceColor',[0.65 0.65 0.65]);
        xo = 0.15;
        errorbar((1:nb)-xo, ms, ss, '.k','LineWidth',1);
        errorbar((1:nb)+xo, mh, sh, '.k','LineWidth',1);
        if SHOW_PTS
            for b = 1:nb
                a = squeeze(A(:,b,p,t)); h = squeeze(H(:,b,p,t));
                plot((b-xo)+0.04*randn(size(a)), a, 'o', 'MarkerSize',3, ...
                    'MarkerEdgeColor',[0.35 0 0],'HandleVisibility','off');
                plot((b+xo)+0.04*randn(size(h)), h, 'o', 'MarkerSize',3, ...
                    'MarkerEdgeColor',[0.3 0.3 0.3],'HandleVisibility','off');
            end
        end
        % significance markers
        yl = ylims(t,:); ylim(yl);
        for b = 1:nb
            r = ST(strcmp(ST.Measure,MEASURE)&strcmp(ST.Band,bands{b,1})& ...
                   strcmp(ST.Phase,phases{p})&strcmp(ST.Timepoint,tpLbl{t}),:);
            if isfinite(r.p) && r.p < 0.05
                mk = '*'; if r.p_FDR < 0.05; mk = '**'; end
                text(b, yl(2)-0.06*range(yl), mk, 'HorizontalAlignment','center', ...
                    'FontSize',14,'FontWeight','bold','Interpreter','none');
            end
        end
        if t==2; plot([0.4 nb+0.6],[0 0],'k:','HandleVisibility','off'); end
        set(gca,'XTick',1:nb,'XTickLabel',bands(:,1),'XTickLabelRotation',40, ...
            'FontSize',8);
        xlim([0.4 nb+0.6]); grid on;
        if p==1; title(tpLbl{t},'FontSize',10); end
        if t==1; ylabel(sprintf('%s\n%s (dB)',phases{p},MEASURE)); end
        if sp==1; legend({'CS active','CS sham'},'Location','best','FontSize',7); end
    end
end
sgt(sprintf(['Chronic stroke: active vs sham spectral power by band  |  %s, %s ' ...
             'electrodes  |  n=5 per group  |  * p<.05, ** FDR q<.05'], ...
             MEASURE, ELEC_SET));
print(fh, fullfile(OUT_DIR,'fig4b_bands.png'),'-dpng','-r150'); close(fh);

fprintf('\nWrote %s\n', OUT_DIR);

%% ==================== LOCAL FUNCTIONS =========================
function Y = tps(X)
% Collapse the four recording blocks to the three plotted timepoints.
% X: subj x band x phase x block  ->  Y: subj x band x phase x timepoint
Y = nan(size(X,1), size(X,2), size(X,3), 3);
Y(:,:,:,1) = X(:,:,:,1);                 % pre  (BL, absolute)
Y(:,:,:,2) = X(:,:,:,3) - X(:,:,:,2);    % LS - ES (a difference)
Y(:,:,:,3) = X(:,:,:,4);                 % post (absolute)
end

function [d,p] = tt2(a,b)
a=a(isfinite(a)); b=b(isfinite(b));
d = mean(a)-mean(b);
if numel(a)<2||numel(b)<2; p=NaN; return; end
se = sqrt(var(a)/numel(a)+var(b)/numel(b));
if se==0; p=NaN; return; end
if exist('ttest2','file')==2
    [~,p] = ttest2(a,b,'Vartype','unequal');
else
    t = d/se; p = 2*(1-0.5*(1+erf(abs(t)/sqrt(2))));
end
end

function q = bh_fdr(p)
% Benjamini-Hochberg. Returns adjusted p-values in the input order.
p = p(:); n = numel(p);
q = nan(n,1);
ok = isfinite(p);
ps = p(ok); m = numel(ps);
[s,i] = sort(ps);
adj = s .* m ./ (1:m)';
for k = m-1:-1:1; adj(k) = min(adj(k), adj(k+1)); end
adj = min(adj,1);
back = nan(m,1); back(i) = adj;
q(ok) = back;
end

function s = sem(x)
x=x(isfinite(x));
if numel(x)<2; s=0; else; s=std(x)/sqrt(numel(x)); end
end

function s = star(p)
if ~isfinite(p); s=''; elseif p<0.05; s=' *'; else; s=''; end
end

function sgt(txt)
if exist('sgtitle','file'); sgtitle(txt,'FontSize',10);
else
    annotation('textbox',[0 0.95 1 0.05],'String',txt,'EdgeColor','none', ...
        'HorizontalAlignment','center','FontWeight','bold');
end
end

function out = tern(c,a,b)
if c; out=a; else; out=b; end
end
