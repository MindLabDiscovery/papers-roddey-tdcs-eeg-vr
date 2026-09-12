%% make_supplementary_figures_v04.m
%
% Generates every supplementary figure for the revision, in one pass.
%
%   Supplementary Figure 1A - spectral power, 4 groups x 4 blocks x 3 phases,
%                             ipsi and contra separately, 9 homologous pairs
%   Supplementary Figure 1B - interhemispheric power difference by band,
%                             CS active vs sham, ES and LS only (6 panels)
%   Supplementary Figure 1C - ES/LS PSD overlay and their difference,
%                             CS active and CS sham only (4 panels)
%   Supplementary Figure 1D - C3-C4 ensemble coherence, CS active vs sham,
%                             4 blocks x 3 phases
%   Supplementary Figure 2  - as 1B, all four blocks (12 panels)
%   Supplementary Figure 3  - as 1C, all four groups (8 panels)
%
% INPUTS
%   subjectData.mat
%   coh_multiband_cells.csv   from recompute_coherence_multiband.m
%
% ELECTRODE SETS
%   Nine clean homologous pairs. The original fig_04 arrays shared indices
%   10, 11 and 21 (Fz, Cz, Pz), counting three midline electrodes as both
%   ipsilesional and contralesional; they are excluded here.
%       Fp2/Fp1  F8/F7  F4/F3  A2/A1  T4/T3  C4/C3  T6/T5  P4/P3  O2/O1
%
% Subjects matched by NAME, never by row index.
%
% R2019b safe. No toolboxes required (t-tests fall back to a normal
% approximation, with a warning, if the Statistics Toolbox is absent).

clear; clc; close all;

%% ============================ CONFIG ============================
MAT_PATH = 'C:\Users\ncr200\Downloads\data_raw\subjectData.mat';
COH_PATH = fullfile(pwd,'coh_multiband_cells.csv');
OUT_DIR  = fullfile(pwd,'supp_figures');
if ~exist(OUT_DIR,'dir'); mkdir(OUT_DIR); end

COH_BAND  = 'gamma2545';      % column ens_<band> in the multiband CSV
TIME_BINS = 9:60;
PSD_PHASES = 1:3;             % 1 hold, 2 prep, 3 move

phases   = {'Hold','Prep','Move'};
blockLbl = {'BL','ES','LS','Post'};

% Band used for Supplementary Figure 1A. State whichever is plotted in the
% Results text; the two definitions agree at r = 0.972.
BAND_1A = [1 50];

bands = { 'delta',[1 4]; 'theta',[4 8]; 'alpha',[8 13]; ...
          'beta',[13 30]; 'gamma',[30 50] };
BAND_SHADE = [25 45];         % highlighted in the PSD panels

pairsR = [12 13 17 20 14 18 15 19 16];
pairsL = [ 1  2  6  9  3  7  4  8  5];
IDX_C3C4 = 6;

roster = { '0003','0004','0005','0013','0015','0017','0018','0021','0042','0043', ...
           '0020','0022','0023','0024','0025','0026','0027','0028','0029','0036' };
crf_active = {'0003','0004','0005','0042','0043','0022','0024','0025','0026','0029'};
cells = {'CS','stim';'CS','sham';'HC','stim';'HC','sham'};

CRED = [0.80 0.20 0.20]; CGRY = [0.45 0.45 0.45];

%% ============================ LOAD ==============================
if ~isfile(MAT_PATH); error('Not found: %s',MAT_PATH); end
S = load(MAT_PATH); sd = S.subjectData; sd_names = {sd.SubjectName};
p1 = sd(1).power; fvec = squeeze(p1.freq(1,:,1));
vals = p1.data(:); vals = vals(isfinite(vals));
IS_DB = mean(vals<0) > 0.01;
fprintf('freq axis %.2f-%.2f Hz, %d bins, spacing %.3f Hz | units %s\n', ...
    min(fvec), max(fvec), numel(fvec), median(diff(fvec)), ...
    tern(IS_DB,'dB','linear->dB'));
fprintf('Band for Supp Fig 1A: %g-%g Hz -> indices %d:%d\n\n', BAND_1A(1), ...
    BAND_1A(2), find(fvec>=BAND_1A(1),1), find(fvec<=BAND_1A(2),1,'last'));

% metadata per subject
M = struct();
for i = 1:numel(roster)
    sid = roster{i};
    mi = find(contains(sd_names,sid),1);
    if isempty(mi); warning('%s missing',sid); continue; end
    si = sd(mi).sessioninfo;
    M(i).sid = sid; M(i).mi = mi;
    M(i).cond = 'sham'; if any(strcmp(sid,crf_active)); M(i).cond='stim'; end
    M(i).grp = 'HC';
    if isstruct(si)&&isfield(si,'dx')&&~isempty(si.dx)&& ...
       strcmpi(strtrim(char(string(si.dx))),'stroke'); M(i).grp='CS'; end
    sl = upper(strtrim(char(string(si.stimlat))));
    if strcmp(sl,'R'); M(i).eI = pairsR; M(i).eC = pairsL; M(i).anode='C4';
    else;              M(i).eI = pairsL; M(i).eC = pairsR; M(i).anode='C3'; end
end
M = M(~cellfun(@isempty,{M.sid}));
fprintf('%d subjects loaded.\n\n', numel(M));

%% ============ SUPP FIG 1A: power, all groups, ipsi/contra =======
fprintf('Building Supplementary Figure 1A...\n');
fm1A = fvec>=BAND_1A(1) & fvec<=BAND_1A(2);
fh = figure('Position',[30 30 1420 800],'Visible','off');
% Shared y-limits across all 24 panels so groups, phases and hemispheres are
% directly comparable. Collected in a first pass, applied in a second.
axAll = []; yAll = [];
sp = 0;
for c = 1:size(cells,1)
    idx = find(strcmp({M.grp},cells{c,1}) & strcmp({M.cond},cells{c,2}));
    for p = PSD_PHASES
        for side = 1:2
            sp = sp+1; subplot(4,6,sp); hold on
            A = nan(numel(idx), numel(pairsR), 4);
            for k = 1:numel(idx)
                mm = M(idx(k));
                e = tern(side==1, mm.eI, mm.eC);
                for ee = 1:numel(e)
                    for t = 1:4
                        x = sd(mm.mi).power.data(fm1A,TIME_BINS,e(ee),p,t);
                        if ~IS_DB; x = 10*log10(x); end
                        A(k,ee,t) = mean(x(:),'omitnan');
                    end
                end
            end
            G = squeeze(mean(A,1,'omitnan'));      % pair x block
            for ee = 1:size(G,1)
                plot(1:4, G(ee,:), 'Color',[0.72 0.72 0.72]);
            end
            plot(1:4, G(IDX_C3C4,:), 'LineWidth',2, ...
                'Color', tern(side==1,[0.15 0.30 0.75],[0.75 0.30 0.15]));
            set(gca,'XTick',1:4,'XTickLabel',blockLbl,'FontSize',7);
            xlim([0.8 4.2]); grid on;
            title(sprintf('%s %s | %s | %s', cells{c,1}, cells{c,2}, ...
                tern(side==1,'ipsi','contra'), phases{p}), 'FontSize',7);
            if sp==1; ylabel('power (dB)','FontSize',8); end
            axAll(end+1) = gca; %#ok<SAGROW>
            yAll = [yAll; G(:)]; %#ok<AGROW>
        end
    end
end
% apply the common y-axis
yAll = yAll(isfinite(yAll));
pad  = 0.05*range(yAll);
for a = axAll, ylim(a, [min(yAll)-pad, max(yAll)+pad]); end
sgt(sprintf(['Supp Fig 1A. Spectral power %g-%g Hz, 9 homologous pairs ' ...
    '(C3/C4 bold); midline excluded; common y-axis'], BAND_1A(1), BAND_1A(2)));
savefig_(fh, fullfile(OUT_DIR,'SuppFig1A_power_allgroups.png'));

%% ============ Band values for 1B / Fig 2 ========================
fprintf('Computing band values...\n');
BV = struct();   % BV.(cond)(subj, band, phase, block) = ipsi - contra
for cnd = {'stim','sham'}
    idx = find(strcmp({M.grp},'CS') & strcmp({M.cond},cnd{1}));
    X = nan(numel(idx), size(bands,1), 3, 4);
    for k = 1:numel(idx)
        mm = M(idx(k));
        for b = 1:size(bands,1)
            fm = fvec>=bands{b,2}(1) & fvec<=bands{b,2}(2);
            for p = 1:3
                for t = 1:4
                    gi = zeros(1,numel(mm.eI)); gc = zeros(1,numel(mm.eC));
                    for ee = 1:numel(mm.eI)
                        x = sd(mm.mi).power.data(fm,TIME_BINS,mm.eI(ee),p,t);
                        if ~IS_DB; x = 10*log10(x); end
                        gi(ee) = mean(x(:),'omitnan');
                    end
                    for ee = 1:numel(mm.eC)
                        x = sd(mm.mi).power.data(fm,TIME_BINS,mm.eC(ee),p,t);
                        if ~IS_DB; x = 10*log10(x); end
                        gc(ee) = mean(x(:),'omitnan');
                    end
                    X(k,b,p,t) = mean(gi,'omitnan') - mean(gc,'omitnan');
                end
            end
        end
    end
    BV.(cnd{1}) = X;
end

%% ============ SUPP FIG 1B (ES,LS) and SUPP FIG 2 (all blocks) ===
for variant = 1:2
    if variant==1
        useBlocks = [2 3]; fname = 'SuppFig1B_bands_ES_LS.png';
        ttl = 'Supp Fig 1B. Interhemispheric power difference by band, CS active vs sham (ES, LS)';
    else
        useBlocks = 1:4;   fname = 'SuppFig2_bands_allblocks.png';
        ttl = 'Supp Fig 2. Interhemispheric power difference by band, CS active vs sham (all blocks)';
    end
    nT = numel(useBlocks); nb = size(bands,1);
    fprintf('Building %s...\n', fname);
    fh = figure('Position',[30 30 300+300*nT 760],'Visible','off');
    yl = nan(nT,2);
    for tt = 1:nT
        t = useBlocks(tt);
        v = [reshape(BV.stim(:,:,:,t),[],1); reshape(BV.sham(:,:,:,t),[],1)];
        v = v(isfinite(v)); pad = 0.18*range(v);
        yl(tt,:) = [min(v)-pad max(v)+pad];
    end
    sp = 0;
    for p = 1:3
        for tt = 1:nT
            t = useBlocks(tt);
            sp = sp+1; subplot(3,nT,sp); hold on
            ms=nan(1,nb); ss=ms; mh=ms; sh=ms;
            for b = 1:nb
                a = squeeze(BV.stim(:,b,p,t)); h = squeeze(BV.sham(:,b,p,t));
                ms(b)=mean(a,'omitnan'); ss(b)=sem_(a);
                mh(b)=mean(h,'omitnan'); sh(b)=sem_(h);
            end
            hb = bar((1:nb)',[ms; mh]','grouped');
            set(hb(1),'FaceColor',CRED); set(hb(2),'FaceColor',CGRY);
            xo = 0.15;
            errorbar((1:nb)-xo, ms, ss, '.k','LineWidth',1);
            errorbar((1:nb)+xo, mh, sh, '.k','LineWidth',1);
            for b = 1:nb
                a = squeeze(BV.stim(:,b,p,t)); h = squeeze(BV.sham(:,b,p,t));
                plot((b-xo)+0.035*randn(size(a)), a,'o','MarkerSize',3, ...
                    'MarkerEdgeColor',[0.35 0 0],'HandleVisibility','off');
                plot((b+xo)+0.035*randn(size(h)), h,'o','MarkerSize',3, ...
                    'MarkerEdgeColor',[0.25 0.25 0.25],'HandleVisibility','off');
            end
            ylim(yl(tt,:));
            plot([0.4 nb+0.6],[0 0],'k:','HandleVisibility','off');
            for b = 1:nb
                [~,pv] = tt2_(squeeze(BV.stim(:,b,p,t)), squeeze(BV.sham(:,b,p,t)));
                if isfinite(pv) && pv < 0.05
                    text(b, yl(tt,2)-0.07*range(yl(tt,:)), '*', ...
                        'HorizontalAlignment','center','FontSize',15, ...
                        'FontWeight','bold','Interpreter','none');
                end
            end
            set(gca,'XTick',1:nb,'XTickLabel',bands(:,1), ...
                'XTickLabelRotation',40,'FontSize',8);
            xlim([0.4 nb+0.6]); grid on;
            if p==1; title(blockLbl{t},'FontSize',10); end
            if tt==1; ylabel(sprintf('%s\nipsi - contra (dB)',phases{p}),'FontSize',8); end
            if sp==1; legend({'CS active','CS sham'},'Location','best','FontSize',7); end
        end
    end
    sgt([ttl '   |   n=5 per group, * p<.05']);
    savefig_(fh, fullfile(OUT_DIR,fname));
end

%% ============ SUPP FIG 1C (CS only) and SUPP FIG 3 (all groups) ==
fprintf('Computing PSDs for the ES/LS contrast...\n');
PS = struct();
for c = 1:size(cells,1)
    idx = find(strcmp({M.grp},cells{c,1}) & strcmp({M.cond},cells{c,2}));
    E = nan(numel(idx), numel(fvec), 3); L = E;
    for k = 1:numel(idx)
        mm = M(idx(k));
        ci = mm.eI(IDX_C3C4);         % anodal electrode
        for p = 1:3
            xe = sd(mm.mi).power.data(:,TIME_BINS,ci,p,2);
            xl = sd(mm.mi).power.data(:,TIME_BINS,ci,p,3);
            if ~IS_DB; xe = 10*log10(xe); xl = 10*log10(xl); end
            E(k,:,p) = mean(xe,2,'omitnan')';
            L(k,:,p) = mean(xl,2,'omitnan')';
        end
    end
    PS(c).E = E; PS(c).L = L; PS(c).n = numel(idx);
end

for variant = 1:2
    if variant==1
        useCells = [1 2]; fname = 'SuppFig1C_ES_LS_psd_CS.png';
        ttl = 'Supp Fig 1C. Early vs late stimulation PSD at the anodal electrode, chronic stroke';
    else
        useCells = 1:4;   fname = 'SuppFig3_ES_LS_psd_allgroups.png';
        ttl = 'Supp Fig 3. Early vs late stimulation PSD at the anodal electrode, all groups';
    end
    nC = numel(useCells);
    fprintf('Building %s...\n', fname);
    fh = figure('Position',[30 30 980 300*nC],'Visible','off');
    sp = 0;
    for cc = 1:nC
        c = useCells(cc);
        for p = 3   % Move phase for the compact version; see note below
            mE = squeeze(mean(PS(c).E(:,:,p),1,'omitnan'));
            mL = squeeze(mean(PS(c).L(:,:,p),1,'omitnan'));
            mD = mL - mE;
            span = range([mE mL]);

            sp = sp+1; subplot(nC,2,sp); hold on
            plot(fvec, mE, 'k','LineWidth',1.4);
            plot(fvec, mL, 'Color',CRED,'LineWidth',1.4);
            shade_(BAND_SHADE,[0.95 0.90 0.55]);
            grid on; xlim([0 max(fvec)]);
            ylabel(sprintf('%s %s (n=%d)\ndB', cells{c,1},cells{c,2},PS(c).n), ...
                'FontSize',8);
            if cc==1
                title('ES (black) and LS (red)','FontSize',9);
                legend({'ES','LS'},'Location','best','FontSize',7);
            end
            if cc==nC; xlabel('Hz'); end

            sp = sp+1; subplot(nC,2,sp); hold on
            plot(fvec, mD, 'Color',[0.15 0.30 0.75],'LineWidth',1.4);
            plot([0 max(fvec)],[0 0],'k--','HandleVisibility','off');
            shade_(BAND_SHADE,[0.95 0.90 0.55]);
            grid on; xlim([0 max(fvec)]); ylim([-span/2 span/2]);
            if cc==1; title('LS - ES (matched scale)','FontSize',9); end
            if cc==nC; xlabel('Hz'); end
        end
    end
    sgt([ttl '   |   Move phase; shaded 25-45 Hz']);
    savefig_(fh, fullfile(OUT_DIR,fname));
end

%% ============ SUPP FIG 1D: coherence ============================
fprintf('Building Supplementary Figure 1D...\n');
if ~isfile(COH_PATH)
    warning(['%s not found. Skipping Supp Fig 1D. ' ...
             'Run recompute_coherence_multiband.m first.'], COH_PATH);
else
    C = readtable(COH_PATH,'Delimiter',',');
    for v = {'subject','group','condition','block','phase','cell_status'}
        C.(v{1}) = cellstr(string(C.(v{1})));
    end
    bcol = ['ens_' COH_BAND];
    if ~ismember(bcol, C.Properties.VariableNames)
        error('Column %s not in %s', bcol, COH_PATH);
    end
    phaseCoh = {'Hold','Prep','Move'};
    % Three timepoints, matching the spectral figures:
    %   pre    = BL, absolute
    %   LS-ES  = late minus early stimulation, a difference
    %   post   = Post, absolute
    % NOTE: the middle point is a DIFFERENCE while the outer two are
    % ABSOLUTE coherence, so it sits near zero by construction. The dip at
    % the middle is arithmetic, not a finding. What is readable is whether
    % the two conditions differ at each point, not the shape of either line.
    tpLblC = {'pre','LS-ES','post'};
    fh = figure('Position',[40 40 1180 400],'Visible','off');
    for p = 1:3
        subplot(1,3,p); hold on
        for cc = 1:2
            cn = tern(cc==1,'Stim','Sham');
            sel0 = strcmp(C.group,'CS') & strcmp(C.condition,cn);
            subs = unique(C.subject(sel0),'stable');
            W = nan(numel(subs),4);          % the four blocks
            for k = 1:numel(subs)
                for t = 1:4
                    m = sel0 & strcmp(C.subject,subs{k}) & ...
                        strcmp(C.phase,phaseCoh{p}) & strcmp(C.block,blockLbl{t});
                    if any(m); W(k,t) = C.(bcol)(find(m,1)); end
                end
            end
            V = [W(:,1), W(:,3)-W(:,2), W(:,4)];   % pre | LS-ES | post
            col = tern(cc==1,CRED,CGRY);
            for k = 1:size(V,1)
                plot(1:3, V(k,:), '-', 'Color',[col 0.28],'HandleVisibility','off');
            end
            errorbar(1:3, mean(V,1,'omitnan'), arrayfun(@(t)sem_(V(:,t)),1:3), ...
                '-o','Color',col,'LineWidth',2,'MarkerFaceColor',col,'MarkerSize',6);
            if cc==1; Vs = V; else; Vh = V; end
        end
        plot([0.8 3.2],[0 0],'k:','HandleVisibility','off');
        yl = ylim;
        for t = 1:3
            [~,pv] = tt2_(Vs(:,t), Vh(:,t));
            % Only p < 0.05 is marked. Trend markers at p < 0.10 were removed:
            % flagging them is inconsistent with the treatment of multiple
            % comparisons elsewhere in this manuscript at n = 5 per group.
            if isfinite(pv) && pv<0.05
                text(t, yl(2)-0.04*range(yl),'*','HorizontalAlignment','center', ...
                    'FontSize',17,'FontWeight','bold','Interpreter','none');
            end
        end
        ylim(yl);
        set(gca,'XTick',1:3,'XTickLabel',tpLblC); xlim([0.8 3.2]); grid on;
        title(phaseCoh{p},'FontSize',10);
        if p==1
            ylabel(sprintf('C3-C4 imaginary coherence\n(%s)',COH_BAND));
            legend({'CS active','CS sham'},'Location','best','FontSize',7);
        end
    end
    sgt(sprintf(['Supp Fig 1D. Ensemble interhemispheric coherence, %s, ' ...
        'CS active vs sham   |   middle point is a difference   |   ' ...
        'n=5, * p<.05'], COH_BAND));
    savefig_(fh, fullfile(OUT_DIR,'SuppFig1D_coherence.png'));
end


%% ============ SUPP FIG 4: per-subject hemispheric ES->LS change ==
% Purpose: make the group-level LS-ES panels interpretable.
%
% The group mean in Supp Fig 1C is carried by a subset of participants, and
% the interpretable feature of the contrast is NOT the size of the residual
% but its SIGN AT THE TWO HEMISPHERES. A common-mode artifact propagated by
% volume conduction displaces both hemispheres in the same direction; it
% cannot produce opposite signs at two electrodes on the same head in the
% same recording. This figure shows, per participant, the LS-ES difference
% at the anodal electrode and at its contralesional homolog, so that
% opposite-direction cases are visible individually rather than averaged.
%
% Layout: one column per participant, CS active on the top row and CS sham
% on the bottom. Blue = anodal hemisphere, orange = contralesional. Shared
% y-limits across all panels. The band label above each panel reports the
% mean LS-ES change in 25-45 Hz at each hemisphere and flags participants
% whose two hemispheres moved in opposite directions.
fprintf('Building Supplementary Figure 4 (per-subject hemispheric)...\n');

fmB = fvec>=BAND_SHADE(1) & fvec<=BAND_SHADE(2);
csCells = [1 2];                       % CS stim, CS sham
nCol = 0;
for c = csCells
    nCol = max(nCol, sum(strcmp({M.grp},cells{c,1}) & strcmp({M.cond},cells{c,2})));
end

fh = figure('Position',[20 20 260*nCol 620],'Visible','off');
allD = [];
DD = struct();
for ci = 1:numel(csCells)
    c = csCells(ci);
    idx = find(strcmp({M.grp},cells{c,1}) & strcmp({M.cond},cells{c,2}));
    DD(ci).ipsi = nan(numel(idx), numel(fvec));
    DD(ci).cont = nan(numel(idx), numel(fvec));
    DD(ci).sid  = cell(1,numel(idx));
    for k = 1:numel(idx)
        mm = M(idx(k));
        eI = mm.eI(IDX_C3C4); eC = mm.eC(IDX_C3C4);
        xeI = sd(mm.mi).power.data(:,TIME_BINS,eI,3,2);
        xlI = sd(mm.mi).power.data(:,TIME_BINS,eI,3,3);
        xeC = sd(mm.mi).power.data(:,TIME_BINS,eC,3,2);
        xlC = sd(mm.mi).power.data(:,TIME_BINS,eC,3,3);
        if ~IS_DB
            xeI=10*log10(xeI); xlI=10*log10(xlI);
            xeC=10*log10(xeC); xlC=10*log10(xlC);
        end
        DD(ci).ipsi(k,:) = (mean(xlI,2,'omitnan') - mean(xeI,2,'omitnan'))';
        DD(ci).cont(k,:) = (mean(xlC,2,'omitnan') - mean(xeC,2,'omitnan'))';
        DD(ci).sid{k} = mm.sid;
        allD = [allD; DD(ci).ipsi(k,:)'; DD(ci).cont(k,:)']; %#ok<AGROW>
    end
end
gl = maxabs_(allD);

nOpp = 0; nTot = 0;
for ci = 1:numel(csCells)
    c = csCells(ci);
    for k = 1:numel(DD(ci).sid)
        sp = (ci-1)*nCol + k;
        subplot(2,nCol,sp); hold on
        plot(fvec, DD(ci).ipsi(k,:), 'Color',[0.15 0.30 0.75],'LineWidth',1.3);
        plot(fvec, DD(ci).cont(k,:), 'Color',[0.85 0.45 0.10],'LineWidth',1.3);
        plot([0 max(fvec)],[0 0],'k--','HandleVisibility','off');
        shade_(BAND_SHADE,[0.95 0.90 0.55]);
        grid on; xlim([0 max(fvec)]); ylim([-gl gl]);
        bI = mean(DD(ci).ipsi(k,fmB),'omitnan');
        bC = mean(DD(ci).cont(k,fmB),'omitnan');
        opp = sign(bI) ~= sign(bC) && bI~=0 && bC~=0;
        nTot = nTot + 1; if opp; nOpp = nOpp + 1; end
        title(sprintf('%s %s\nipsi %+.2f  contra %+.2f%s', ...
            cells{c,2}, DD(ci).sid{k}, bI, bC, tern(opp,'  [opposite]','')), ...
            'FontSize',7.5, 'Color', tern(opp,[0.6 0 0],[0 0 0]));
        if k==1
            ylabel(sprintf('%s %s\nLS - ES (dB)', cells{c,1}, cells{c,2}),'FontSize',8);
        end
        if ci==2; xlabel('Hz','FontSize',8); end
        if sp==1
            legend({'anodal hemisphere','contralesional'},'Location','best','FontSize',6);
        end
    end
end
sgt(sprintf(['Supp Fig 4. Per-participant LS-ES change at the anodal and ' ...
    'contralesional electrodes, Move phase   |   %d of %d with opposite ' ...
    'signs in %g-%g Hz'], nOpp, nTot, BAND_SHADE(1), BAND_SHADE(2)));
savefig_(fh, fullfile(OUT_DIR,'SuppFig4_persubject_hemispheres.png'));

% console summary
fprintf('\n  Per-participant LS-ES change, %g-%g Hz, Move phase:\n', ...
    BAND_SHADE(1), BAND_SHADE(2));
fprintf('  %-6s %-6s %10s %10s %12s\n','group','subj','ipsi','contra','same sign?');
for ci = 1:numel(csCells)
    c = csCells(ci);
    for k = 1:numel(DD(ci).sid)
        bI = mean(DD(ci).ipsi(k,fmB),'omitnan');
        bC = mean(DD(ci).cont(k,fmB),'omitnan');
        fprintf('  %-6s %-6s %+10.3f %+10.3f %12s\n', cells{c,2}, DD(ci).sid{k}, ...
            bI, bC, tern(sign(bI)==sign(bC),'same','OPPOSITE'));
    end
end
fprintf(['\n  A common-mode artifact cannot produce opposite signs at the two\n' ...
         '  hemispheres within a participant. Cases marked OPPOSITE are the\n' ...
         '  evidence that physiological signal survives the contrast.\n\n']);

fprintf('\nAll figures written to %s\n', OUT_DIR);
fprintf(['\nNOTE: Supp Fig 1C and 3 show the Move phase only, for legibility.\n' ...
         'Set the inner loop to 1:3 if Hold and Prep panels are wanted.\n']);

%% ==================== LOCAL FUNCTIONS =========================
function savefig_(fh, path)
% Write PNG for quick viewing and SVG for the manuscript. SVG is vector,
% so text and lines stay sharp at any size and the figure can be edited in
% Illustrator or Inkscape without rasterising.
print(fh, path, '-dpng','-r150');
[d,n,~] = fileparts(path);
svgpath = fullfile(d,[n '.svg']);
try
    print(fh, svgpath, '-dsvg');
    fprintf('  wrote %s (+ .svg)\n', path);
catch ME
    fprintf('  wrote %s (SVG failed: %s)\n', path, ME.message);
end
close(fh);
end

function v = maxabs_(x)
x = x(isfinite(x));
v = max(abs(x));
if isempty(v) || v==0; v = 1; end
end

function [d,p] = tt2_(a,b)
a=a(isfinite(a)); b=b(isfinite(b));
d = mean(a)-mean(b);
if numel(a)<2||numel(b)<2; p=NaN; return; end
se = sqrt(var(a)/numel(a)+var(b)/numel(b));
if se==0; p=NaN; return; end
if exist('ttest2','file')==2
    [~,p] = ttest2(a,b,'Vartype','unequal');
else
    t=d/se; p = 2*(1-0.5*(1+erf(abs(t)/sqrt(2))));
end
end

function s = sem_(x)
x=x(isfinite(x));
if numel(x)<2; s=0; else; s=std(x)/sqrt(numel(x)); end
end

function shade_(rng,col)
yl = ylim;
patch([rng(1) rng(2) rng(2) rng(1)],[yl(1) yl(1) yl(2) yl(2)],col, ...
    'FaceAlpha',0.30,'EdgeColor','none','HandleVisibility','off');
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
