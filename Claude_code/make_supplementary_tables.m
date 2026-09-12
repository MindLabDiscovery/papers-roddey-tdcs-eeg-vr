%% make_supplementary_tables.m
%
% Generates the three supplementary tables.
%
%   SuppTable1_drift.csv       direct-current drift characteristics
%   SuppTable2_coherence.csv   C3-C4 ensemble coherence by frequency band
%   SuppTable3_regression.csv  brain-behaviour associations, raw and FDR
%
% INPUTS
%   subjectData.mat
%   coh_multiband_cells.csv          from recompute_coherence_multiband.m
%   kinematics_long.csv              from extract_kinematics.m
%   spectral_kinematic_regression.csv (optional) from
%       run_spectral_kinematic_regression.m -- merged into Table 3 if present
%
% NOTE ON TABLE 3
%   The coherence-kinematic regressions are recomputed here directly from
%   the multiband CSV, so they use the SAME band as the reported coherence
%   result. The earlier regression run used the 30-50 Hz column and is
%   superseded.
%
% R2019b safe.

clear; clc; close all;

%% ============================ CONFIG ============================
MAT_PATH = 'C:\Users\ncr200\Downloads\data_raw\subjectData.mat';
COH_PATH = fullfile(pwd,'coh_multiband_cells.csv');
KIN_PATH = fullfile(pwd,'kinematics_long.csv');
SPEC_PATH= fullfile(pwd,'spectral_kinematic_regression.csv');   % optional
OUT_DIR  = fullfile(pwd,'supp_tables');
if ~exist(OUT_DIR,'dir'); mkdir(OUT_DIR); end

COH_BAND  = 'gamma2545';
TIME_BINS = 9:60;
PRIMARY_PHASE = 3;
phases   = {'Hold','Prep','Move'};
blockLbl = {'BL','ES','LS','Post'};

bands = { 'drift',[1 4]; 'theta',[4 8]; 'alpha',[8 13]; ...
          'beta',[13 30]; 'gamma',[30 50] };

pairsR = [12 13 17 20 14 18 15 19 16];
pairsL = [ 1  2  6  9  3  7  4  8  5];
IDX_C3C4 = 6;

roster = { '0003','0004','0005','0013','0015','0017','0018','0021','0042','0043', ...
           '0020','0022','0023','0024','0025','0026','0027','0028','0029','0036' };
crf_active = {'0003','0004','0005','0042','0043','0022','0024','0025','0026','0029'};
cells = {'CS','stim';'CS','sham';'HC','stim';'HC','sham'};

%% ============================ LOAD ==============================
S = load(MAT_PATH); sd = S.subjectData; sd_names = {sd.SubjectName};
p1 = sd(1).power; fvec = squeeze(p1.freq(1,:,1));
vals = p1.data(:); vals = vals(isfinite(vals));
IS_DB = mean(vals<0) > 0.01;

meta = struct();
for i = 1:numel(roster)
    sid = roster{i};
    mi = find(contains(sd_names,sid),1);
    if isempty(mi); continue; end
    si = sd(mi).sessioninfo;
    meta(i).sid=sid; meta(i).mi=mi;
    meta(i).cond='sham'; if any(strcmp(sid,crf_active)); meta(i).cond='stim'; end
    meta(i).grp='HC';
    if isstruct(si)&&isfield(si,'dx')&&~isempty(si.dx)&& ...
       strcmpi(strtrim(char(string(si.dx))),'stroke'); meta(i).grp='CS'; end
    sl = upper(strtrim(char(string(si.stimlat))));
    if strcmp(sl,'R'); meta(i).anode = pairsR(IDX_C3C4);
    else;              meta(i).anode = pairsL(IDX_C3C4); end
end
meta = meta(~cellfun(@isempty,{meta.sid}));

%% ==================== TABLE 1: DRIFT ===========================
fprintf('Building Supplementary Table 1 (drift)...\n');
rows = {};
for c = 1:size(cells,1)
    idx = find(strcmp({meta.grp},cells{c,1}) & strcmp({meta.cond},cells{c,2}));
    for b = 1:size(bands,1)
        fm = fvec>=bands{b,2}(1) & fvec<=bands{b,2}(2);
        V = nan(numel(idx),4);
        for k = 1:numel(idx)
            mm = meta(idx(k));
            for t = 1:4
                x = sd(mm.mi).power.data(fm,TIME_BINS,mm.anode,PRIMARY_PHASE,t);
                if ~IS_DB; x = 10*log10(x); end
                V(k,t) = mean(x(:),'omitnan');
            end
        end
        dES = V(:,2)-V(:,1); dLS = V(:,3)-V(:,1); dPO = V(:,4)-V(:,1);
        rows(end+1,:) = { cells{c,1}, cells{c,2}, bands{b,1}, ...
            sprintf('%g-%g', bands{b,2}(1), bands{b,2}(2)), numel(idx), ...
            mean(V(:,1),'omitnan'), sem_(V(:,1)), ...
            mean(dES,'omitnan'), sem_(dES), sum(dES>0), ...
            mean(dLS,'omitnan'), sem_(dLS), sum(dLS>0), ...
            mean(dPO,'omitnan'), sem_(dPO) }; %#ok<AGROW>
    end
end
T1 = cell2table(rows,'VariableNames', ...
    {'Group','Condition','Band','Range_Hz','n','BL_mean','BL_sem', ...
     'ES_minus_BL','ES_sem','ES_n_positive', ...
     'LS_minus_BL','LS_sem','LS_n_positive','Post_minus_BL','Post_sem'});
% drift-to-gamma ratio per group
T1.drift_gamma_ratio = nan(height(T1),1);
for c = 1:size(cells,1)
    m = strcmp(T1.Group,cells{c,1}) & strcmp(T1.Condition,cells{c,2});
    dr = T1.LS_minus_BL(m & strcmp(T1.Band,'drift'));
    ga = T1.LS_minus_BL(m & strcmp(T1.Band,'gamma'));
    if ~isempty(dr) && ~isempty(ga) && ga~=0
        T1.drift_gamma_ratio(m & strcmp(T1.Band,'drift')) = dr/ga;
    end
end
writetable(T1, fullfile(OUT_DIR,'SuppTable1_drift.csv'));
fprintf('  %d rows\n', height(T1));

%% ==================== TABLE 2: COHERENCE =======================
fprintf('Building Supplementary Table 2 (coherence)...\n');
if ~isfile(COH_PATH)
    warning('%s not found; skipping Table 2.', COH_PATH);
else
    C = readtable(COH_PATH,'Delimiter',',');
    for v = {'subject','group','condition','block','phase','cell_status'}
        C.(v{1}) = cellstr(string(C.(v{1})));
    end
    bcols = C.Properties.VariableNames(startsWith(C.Properties.VariableNames,'ens_'));
    rows = {};
    for bi = 1:numel(bcols)
        bn = bcols{bi}(5:end);
        for p = 1:3
            for t = 1:4
                a = C.(bcols{bi})(strcmp(C.group,'CS')&strcmp(C.condition,'Stim')& ...
                    strcmp(C.phase,phases{p})&strcmp(C.block,blockLbl{t}));
                h = C.(bcols{bi})(strcmp(C.group,'CS')&strcmp(C.condition,'Sham')& ...
                    strcmp(C.phase,phases{p})&strcmp(C.block,blockLbl{t}));
                a=a(isfinite(a)); h=h(isfinite(h));
                [d,pv] = tt2_(a,h);
                rows(end+1,:) = {bn, phases{p}, blockLbl{t}, numel(a), numel(h), ...
                    mean(a), sem_(a), mean(h), sem_(h), d, pv}; %#ok<AGROW>
            end
        end
    end
    T2 = cell2table(rows,'VariableNames', ...
        {'Band','Phase','Block','n_active','n_sham','mean_active','sem_active', ...
         'mean_sham','sem_sham','diff_active_minus_sham','p'});
    T2.p_FDR = bh_(T2.p);
    writetable(T2, fullfile(OUT_DIR,'SuppTable2_coherence.csv'));
    fprintf('  %d rows | %d at p<.05 | %d at FDR q<.05\n', height(T2), ...
        sum(T2.p<0.05), sum(T2.p_FDR<0.05));
end

%% ==================== TABLE 3: REGRESSIONS =====================
fprintf('Building Supplementary Table 3 (brain-behaviour)...\n');
if ~isfile(KIN_PATH)
    warning('%s not found; skipping Table 3.', KIN_PATH);
else
    K = readtable(KIN_PATH,'Delimiter',',');
    if ~iscell(K.SubjectID)
        K.SubjectID = arrayfun(@(x)sprintf('%04d',x),K.SubjectID,'UniformOutput',false);
    end
    K.Block = cellstr(string(K.Block)); K.Metric = cellstr(string(K.Metric));
    metrics = unique(K.Metric,'stable');

    kin = containers.Map();
    for i = 1:numel(roster)
        sid = roster{i};
        Mk = nan(numel(metrics),4);
        for m = 1:numel(metrics)
            for b = 1:4
                v = K.Value(strcmp(K.SubjectID,sid)&strcmp(K.Metric,metrics{m})& ...
                            strcmp(K.Block,blockLbl{b}));
                Mk(m,b) = mean(v,'omitnan');
            end
        end
        kin(sid) = Mk;
    end

    rows = {};
    if isfile(COH_PATH)
        C = readtable(COH_PATH,'Delimiter',',');
        for v = {'subject','group','condition','block','phase'}
            C.(v{1}) = cellstr(string(C.(v{1})));
        end
        C.sid = cell(height(C),1);
        for i = 1:height(C)
            tok = regexp(C.subject{i},'(\d{4})$','tokens','once');
            C.sid{i} = tern(isempty(tok), C.subject{i}, '');
            if ~isempty(tok); C.sid{i} = tok{1}; end
        end
        bcol = ['ens_' COH_BAND];
        tpDef = { 'BL',[1 0 0 0]; 'LSminusES',[0 -1 1 0]; 'Post',[0 0 0 1] };
        for c = 1:size(cells,1)
            grpU = cells{c,1};
            condU = tern(strcmp(cells{c,2},'stim'),'Stim','Sham');
            subs = unique(C.sid(strcmp(C.group,grpU)&strcmp(C.condition,condU)),'stable');
            for p = 1:3
                for tp = 1:size(tpDef,1)
                    w = tpDef{tp,2};
                    x = nan(numel(subs),1);
                    for k = 1:numel(subs)
                        vv = nan(1,4);
                        for t = 1:4
                            m = strcmp(C.sid,subs{k})&strcmp(C.phase,phases{p})& ...
                                strcmp(C.block,blockLbl{t});
                            if any(m); vv(t) = C.(bcol)(find(m,1)); end
                        end
                        x(k) = w*vv';
                    end
                    for m = 1:numel(metrics)
                        y = nan(numel(subs),1);
                        for k = 1:numel(subs)
                            if ~isKey(kin,subs{k}); continue; end
                            Mk = kin(subs{k}); y(k) = Mk(m,:)*w';
                        end
                        ok = isfinite(x)&isfinite(y);
                        if sum(ok)<3; continue; end
                        [r,pv] = corr_(x(ok),y(ok));
                        rows(end+1,:) = {'coherence',COH_BAND,cells{c,1}, ...
                            cells{c,2},phases{p},tpDef{tp,1},metrics{m}, ...
                            sum(ok),r,r^2,pv}; %#ok<AGROW>
                    end
                end
            end
        end
    end

    T3 = cell2table(rows,'VariableNames', ...
        {'Measure','Band','Group','Condition','Phase','Timepoint','Metric', ...
         'n','r','R2','p'});

    % merge the spectral regressions if that file is present
    if isfile(SPEC_PATH)
        SP = readtable(SPEC_PATH,'Delimiter',',');
        add = table(repmat({'spectral power'},height(SP),1), SP.Band, SP.Group, ...
            lower(SP.Condition), repmat({'Move'},height(SP),1), ...
            repmat({'LSminusES'},height(SP),1), SP.Metric, SP.n, SP.r, SP.R2, SP.p, ...
            'VariableNames', T3.Properties.VariableNames);
        T3 = [T3; add];
        fprintf('  merged %d spectral regression rows\n', height(SP));
    else
        fprintf('  spectral regression file not found; coherence rows only\n');
    end

    T3.p_FDR = bh_(T3.p);
    writetable(T3, fullfile(OUT_DIR,'SuppTable3_regression.csv'));
    fprintf('  %d rows | %d at p<.05 | %d at FDR q<.05\n', height(T3), ...
        sum(T3.p<0.05), sum(T3.p_FDR<0.05));

    fprintf('\n  Hit rates by condition (the null-condition calibration):\n');
    for c = 1:size(cells,1)
        m = strcmp(T3.Group,cells{c,1}) & strcmp(T3.Condition,cells{c,2});
        if ~any(m); continue; end
        fprintf('    %s %-5s : %d/%d nominal (%.1f%%), %d surviving FDR\n', ...
            cells{c,1}, cells{c,2}, sum(m&T3.p<0.05), sum(m), ...
            100*sum(m&T3.p<0.05)/sum(m), sum(m&T3.p_FDR<0.05));
    end
end

fprintf('\nTables written to %s\n', OUT_DIR);

%% ==================== LOCAL FUNCTIONS =========================
function [d,p] = tt2_(a,b)
a=a(isfinite(a)); b=b(isfinite(b));
d = mean(a)-mean(b);
if numel(a)<2||numel(b)<2; p=NaN; return; end
se = sqrt(var(a)/numel(a)+var(b)/numel(b));
if se==0; p=NaN; return; end
if exist('ttest2','file')==2
    [~,p] = ttest2(a,b,'Vartype','unequal');
else
    t=d/se; p=2*(1-0.5*(1+erf(abs(t)/sqrt(2))));
end
end

function [r,p] = corr_(x,y)
n=numel(x);
xc=x-mean(x); yc=y-mean(y);
den=sqrt(sum(xc.^2)*sum(yc.^2));
if den==0; r=NaN; p=NaN; return; end
r=sum(xc.*yc)/den;
if n>2 && abs(r)<1
    t=r*sqrt((n-2)/(1-r^2));
    if exist('tcdf','file')==2; p=2*(1-tcdf(abs(t),n-2));
    else; p=2*(1-0.5*(1+erf(abs(t)/sqrt(2)))); end
elseif abs(r)>=1; p=0; else; p=NaN; end
end

function q = bh_(p)
p=p(:); n=numel(p); q=nan(n,1);
ok=isfinite(p); ps=p(ok); m=numel(ps);
if m==0; return; end
[s,i]=sort(ps);
adj=s.*m./(1:m)';
for k=m-1:-1:1; adj(k)=min(adj(k),adj(k+1)); end
adj=min(adj,1);
back=nan(m,1); back(i)=adj; q(ok)=back;
end

function s = sem_(x)
x=x(isfinite(x));
if numel(x)<2; s=0; else; s=std(x)/sqrt(numel(x)); end
end

function out = tern(c,a,b)
if c; out=a; else; out=b; end
end
