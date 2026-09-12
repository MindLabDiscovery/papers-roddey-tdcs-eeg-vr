%% run_kinematic_anova_table.m
%
% PURPOSE
%   Produce the complete kinematic ANOVA table: every kinematic variable,
%   every model term, in one place.
%
% WHY A TABLE
%   Reviewer 1's objection was not to the statistics but to selective
%   reporting: post-hoc comparisons were shown within the active group
%   only, implying a group-specific effect the interaction did not support.
%   Reporting the full model for every variable makes that objection
%   structurally impossible, and lets the within-group tests be shown for
%   BOTH conditions without the text becoming unreadable.
%
% WHAT IS COMPUTED, per kinematic variable
%   1. Two-way MIXED ANOVA
%        between factor : stimulation condition (active, sham)
%        within factor  : timepoint (BL, ES, LS, Post)
%      Note this is a mixed, not fully repeated, design: participants
%      received either active or sham, never both. The interaction is
%      therefore tested against between-subject variance with 8 df, which
%      is the least sensitive term in the model.
%   2. Greenhouse-Geisser epsilon and corrected p for the within-subject
%      terms. With four timepoints and n=5 per group, sphericity cannot be
%      meaningfully assessed, so the corrected values are the conservative
%      default.
%   3. One-way repeated-measures ANOVA within EACH condition separately.
%      This answers "did this group change over time", which is a distinct
%      question from the interaction and does not depend on it. Reported
%      for both conditions so the comparison is symmetric.
%   4. Direct between-condition contrast of the early-to-late change.
%      This is the comparison that would license a stimulation-specific
%      claim.
%
% GROUP
%   Chronic stroke by default. Set TARGET_GROUP = 'HC' for controls.
%   Reviewer 1 asked that both be reported; run twice.
%
% INPUT
%   kinematics_long.csv from extract_kinematics.m
%
% OUTPUT
%   kinematic_anova_table_<group>.csv   one row per variable
%   console: formatted table
%
% R2019b safe. Sums of squares are computed directly, so no Statistics
% Toolbox is required; p-values use fcdf when available and a
% Wilson-Hilferty approximation otherwise.

clear; clc;

%% ============================ CONFIG ============================
KIN_PATH = fullfile(pwd,'kinematics_long.csv');
OUT_DIR  = fullfile(pwd,'anova_out');
if ~exist(OUT_DIR,'dir'); mkdir(OUT_DIR); end

TARGET_GROUP = 'HC';        % 'CS' or 'HC'
blockLbl = {'BL','ES','LS','Post'};

cs_ids     = {'0003','0004','0005','0013','0015','0017','0018','0021','0042','0043'};
crf_active = {'0003','0004','0005','0042','0043','0022','0024','0025','0026','0029'};

%% ============================ LOAD ==============================
if ~isfile(KIN_PATH); error('Not found: %s', KIN_PATH); end
T = readtable(KIN_PATH,'Delimiter',',');
if ~iscell(T.SubjectID)
    T.SubjectID = arrayfun(@(x)sprintf('%04d',x),T.SubjectID,'UniformOutput',false);
end
T.Block  = cellstr(string(T.Block));
T.Metric = cellstr(string(T.Metric));
T.Group  = cellstr(string(T.Group));
metrics  = unique(T.Metric,'stable');

subs = unique(T.SubjectID,'stable');
keep = {};
for i = 1:numel(subs)
    sid = subs{i};
    isCS = any(strcmp(sid,cs_ids));
    if (strcmp(TARGET_GROUP,'CS') && isCS) || (strcmp(TARGET_GROUP,'HC') && ~isCS)
        keep{end+1} = sid; %#ok<AGROW>
    end
end
cond = cellfun(@(s) tern(any(strcmp(s,crf_active)),'active','sham'), keep, ...
    'UniformOutput', false);
iA = find(strcmp(cond,'active')); iS = find(strcmp(cond,'sham'));
fprintf('%s group: %d active, %d sham\n\n', TARGET_GROUP, numel(iA), numel(iS));

%% ==================== BUILD DATA MATRICES =======================
% Y{metric} = subjects x 4 timepoints, rows ordered as `keep`
Y = cell(1,numel(metrics));
for m = 1:numel(metrics)
    A = nan(numel(keep),4);
    for k = 1:numel(keep)
        for t = 1:4
            v = T.Value(strcmp(T.SubjectID,keep{k}) & ...
                        strcmp(T.Metric,metrics{m}) & strcmp(T.Block,blockLbl{t}));
            A(k,t) = mean(v,'omitnan');
        end
    end
    Y{m} = A;
end

%% ==================== ANALYSIS ==================================
rows = {};
for m = 1:numel(metrics)
    A = Y{m};
    grp = [ones(numel(iA),1); 2*ones(numel(iS),1)];
    D   = [A(iA,:); A(iS,:)];
    ok  = all(isfinite(D),2);
    D = D(ok,:); grp = grp(ok);

    R = mixed_anova(D, grp);

    % one-way RM within each condition
    [F1a,p1a,df1a,df2a] = rm_oneway(A(iA,:));
    [F1s,p1s,df1s,df2s] = rm_oneway(A(iS,:));

    % ES -> LS change, between conditions
    dA = A(iA,3)-A(iA,2); dS = A(iS,3)-A(iS,2);
    [tD,pD] = tt2(dA,dS);
    dz_A = mean(dA,'omitnan')/std(dA,'omitnan');

    rows(end+1,:) = { metrics{m}, ...
        R.F_time, R.df_time(1), R.df_time(2), R.p_time, R.p_time_gg, R.eps_gg, ...
        R.F_cond, R.df_cond(1), R.df_cond(2), R.p_cond, ...
        R.F_int,  R.df_int(1),  R.df_int(2),  R.p_int,  R.p_int_gg, ...
        F1a, df1a, df2a, p1a, F1s, df1s, df2s, p1s, ...
        mean(dA,'omitnan'), dz_A, mean(dS,'omitnan'), tD, pD }; %#ok<AGROW>
end

vn = {'Metric', ...
 'F_time','df_time_num','df_time_den','p_time','p_time_GG','epsilon_GG', ...
 'F_condition','df_cond_num','df_cond_den','p_condition', ...
 'F_interaction','df_int_num','df_int_den','p_interaction','p_interaction_GG', ...
 'F_active_oneway','df_act_num','df_act_den','p_active_oneway', ...
 'F_sham_oneway','df_sham_num','df_sham_den','p_sham_oneway', ...
 'ESLS_change_active','ESLS_dz_active','ESLS_change_sham', ...
 't_between','p_between'};
TB = cell2table(rows,'VariableNames',vn);
writetable(TB, fullfile(OUT_DIR, sprintf('kinematic_anova_table_%s.csv',TARGET_GROUP)));

%% ==================== CONSOLE ==================================
fprintf('================================================================================\n');
fprintf('  KINEMATIC ANOVA, %s GROUP\n', TARGET_GROUP);
fprintf('  Two-way mixed: condition (between) x timepoint (within)\n');
fprintf('================================================================================\n\n');
fprintf('%-20s %-22s %-20s %-24s\n','variable','TIME','CONDITION','CONDITION x TIME');
fprintf('%-20s %-22s %-20s %-24s\n','','F(df) p [GG p]','F(df) p','F(df) p [GG p]');
fprintf('%s\n', repmat('-',1,92));
for m = 1:height(TB)
    fprintf('%-20s F(%d,%d)=%5.2f p=%.4f%s [%.4f]  F(%d,%d)=%5.2f p=%.4f  F(%d,%d)=%5.2f p=%.4f%s [%.4f]\n', ...
        TB.Metric{m}, TB.df_time_num(m), TB.df_time_den(m), TB.F_time(m), ...
        TB.p_time(m), star(TB.p_time(m)), TB.p_time_GG(m), ...
        TB.df_cond_num(m), TB.df_cond_den(m), TB.F_condition(m), TB.p_condition(m), ...
        TB.df_int_num(m), TB.df_int_den(m), TB.F_interaction(m), ...
        TB.p_interaction(m), star(TB.p_interaction(m)), TB.p_interaction_GG(m));
end

fprintf('\n================================================================================\n');
fprintf('  WITHIN-CONDITION ONE-WAY RM ANOVA (reported for BOTH conditions)\n');
fprintf('================================================================================\n');
fprintf('Answers "did this group change over time". A separate question from the\n');
fprintf('interaction; does not depend on it. Shown for both so the report is symmetric.\n\n');
fprintf('%-20s %-26s %-26s\n','variable','ACTIVE','SHAM');
fprintf('%s\n', repmat('-',1,74));
for m = 1:height(TB)
    fprintf('%-20s F(%d,%d)=%6.2f p=%.4f%s  F(%d,%d)=%6.2f p=%.4f%s\n', ...
        TB.Metric{m}, TB.df_act_num(m), TB.df_act_den(m), TB.F_active_oneway(m), ...
        TB.p_active_oneway(m), star(TB.p_active_oneway(m)), ...
        TB.df_sham_num(m), TB.df_sham_den(m), TB.F_sham_oneway(m), ...
        TB.p_sham_oneway(m), star(TB.p_sham_oneway(m)));
end

fprintf('\n================================================================================\n');
fprintf('  EARLY-TO-LATE CHANGE, BETWEEN CONDITIONS\n');
fprintf('================================================================================\n');
fprintf('The comparison that would license a stimulation-specific claim.\n\n');
fprintf('%-20s %12s %8s %12s %10s %10s\n', ...
    'variable','active','dz','sham','t','p');
fprintf('%s\n', repmat('-',1,78));
for m = 1:height(TB)
    fprintf('%-20s %+12.4f %8.2f %+12.4f %+10.3f %10.4f%s\n', ...
        TB.Metric{m}, TB.ESLS_change_active(m), TB.ESLS_dz_active(m), ...
        TB.ESLS_change_sham(m), TB.t_between(m), TB.p_between(m), ...
        star(TB.p_between(m)));
end

fprintf('\n--- counts ---\n');
fprintf('  significant TIME effects        : %d of %d\n', sum(TB.p_time<0.05), height(TB));
fprintf('  significant INTERACTIONS        : %d of %d\n', sum(TB.p_interaction<0.05), height(TB));
fprintf('  significant BETWEEN comparisons : %d of %d\n', sum(TB.p_between<0.05), height(TB));
fprintf('  active one-way significant      : %d of %d\n', sum(TB.p_active_oneway<0.05), height(TB));
fprintf('  sham   one-way significant      : %d of %d\n', sum(TB.p_sham_oneway<0.05), height(TB));
fprintf(['\nNOTE: %d kinematic variables tested. Interpret the count of\n' ...
         'significant results against a chance expectation of %.1f per column.\n'], ...
         height(TB), 0.05*height(TB));
fprintf('\nWrote %s\n', fullfile(OUT_DIR, sprintf('kinematic_anova_table_%s.csv',TARGET_GROUP)));

%% ==================== LOCAL FUNCTIONS =========================
function R = mixed_anova(D, grp)
% Two-way mixed ANOVA: one between factor (grp), one within factor (columns).
% Sums of squares computed directly.
[n, k] = size(D);
g = unique(grp);
ng = numel(g);

grand = mean(D(:));
SS_tot = sum((D(:)-grand).^2);

% between-subject partition
subjM = mean(D,2);
SS_bs = k * sum((subjM - grand).^2);
grpM = arrayfun(@(x) mean(subjM(grp==x)), g);
nper = arrayfun(@(x) sum(grp==x), g);
SS_cond = k * sum(nper .* (grpM - grand).^2);
SS_bs_err = SS_bs - SS_cond;
df_cond = ng - 1;
df_bs_err = n - ng;

% within-subject partition
timeM = mean(D,1);
SS_time = n * sum((timeM - grand).^2);
SS_ws = SS_tot - SS_bs;
cellM = nan(ng,k);
for i = 1:ng, cellM(i,:) = mean(D(grp==g(i),:),1); end
SS_cells = 0;
for i = 1:ng
    SS_cells = SS_cells + nper(i)*sum((cellM(i,:) - grand).^2);
end
SS_int = SS_cells - SS_cond - SS_time;
SS_ws_err = SS_ws - SS_time - SS_int;
df_time = k - 1;
df_int  = (k-1)*(ng-1);
df_ws_err = (n - ng)*(k - 1);

MS_cond = SS_cond/df_cond;      MS_bs_err = SS_bs_err/df_bs_err;
MS_time = SS_time/df_time;      MS_ws_err = SS_ws_err/df_ws_err;
MS_int  = SS_int/df_int;

R.F_cond = MS_cond/MS_bs_err;  R.df_cond = [df_cond df_bs_err];
R.F_time = MS_time/MS_ws_err;  R.df_time = [df_time df_ws_err];
R.F_int  = MS_int /MS_ws_err;  R.df_int  = [df_int  df_ws_err];
R.p_cond = fp(R.F_cond, df_cond, df_bs_err);
R.p_time = fp(R.F_time, df_time, df_ws_err);
R.p_int  = fp(R.F_int,  df_int,  df_ws_err);

% Greenhouse-Geisser epsilon from the pooled within-subject covariance
Dc = D - repmat(mean(D,2),1,k);
Sigma = cov(Dc);
lam = eig(Sigma); lam = lam(lam > 1e-12);
if numel(lam) < 2
    R.eps_gg = 1;
else
    R.eps_gg = (sum(lam)^2) / ((numel(lam)) * sum(lam.^2));
    R.eps_gg = min(max(R.eps_gg, 1/(k-1)), 1);
end
R.p_time_gg = fp(R.F_time, df_time*R.eps_gg, df_ws_err*R.eps_gg);
R.p_int_gg  = fp(R.F_int,  df_int *R.eps_gg, df_ws_err*R.eps_gg);
end

function [F,p,df1,df2] = rm_oneway(D)
% One-way repeated-measures ANOVA on subjects x timepoints.
D = D(all(isfinite(D),2),:);
[n,k] = size(D);
if n < 2 || k < 2; F=NaN; p=NaN; df1=NaN; df2=NaN; return; end
grand = mean(D(:));
SS_time = n*sum((mean(D,1)-grand).^2);
SS_subj = k*sum((mean(D,2)-grand).^2);
SS_tot  = sum((D(:)-grand).^2);
SS_err  = SS_tot - SS_time - SS_subj;
df1 = k-1; df2 = (n-1)*(k-1);
F = (SS_time/df1)/(SS_err/df2);
p = fp(F,df1,df2);
end

function p = fp(F,df1,df2)
if ~isfinite(F) || F<=0 || df1<=0 || df2<=0; p = NaN; return; end
if exist('fcdf','file')==2
    p = 1 - fcdf(F,df1,df2);
else
    % Wilson-Hilferty approximation to the F distribution
    a = 2/(9*df1); b = 2/(9*df2);
    z = ((1-b)*F^(1/3) - (1-a)) / sqrt(b*F^(2/3) + a);
    p = 1 - 0.5*(1+erf(z/sqrt(2)));
end
end

function [t,p] = tt2(a,b)
a=a(isfinite(a)); b=b(isfinite(b));
if numel(a)<2||numel(b)<2; t=NaN; p=NaN; return; end
se = sqrt(var(a)/numel(a)+var(b)/numel(b));
if se==0; t=NaN; p=NaN; return; end
t = (mean(a)-mean(b))/se;
if exist('ttest2','file')==2
    [~,p] = ttest2(a,b,'Vartype','unequal');
else
    p = 2*(1-0.5*(1+erf(abs(t)/sqrt(2))));
end
end

function s = star(p)
if ~isfinite(p); s=' '; elseif p<0.05; s='*'; else; s=' '; end
end

function out = tern(c,a,b)
if c; out=a; else; out=b; end
end
