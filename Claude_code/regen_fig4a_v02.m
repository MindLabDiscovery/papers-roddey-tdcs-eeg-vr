%% regen_fig4a_v02.m
%
% PURPOSE
%   Regenerate Figure 4A with two corrections and two band definitions, to
%   test whether the published pattern depends on low-frequency drift.
%
% CORRECTION 1 — ELECTRODE SETS
%   The original elec_ipsi/elec_cont arrays share indices 10, 11 and 21
%   (Fz, Cz, Pz). Those three midline electrodes were counted as BOTH
%   ipsilesional and contralesional, contributing exactly zero to the
%   ipsi-contra difference while still occupying a quarter of each
%   12-electrode average. They are removed here, leaving 9 clean
%   homologous pairs:
%       Fp2/Fp1  F8/F7  F4/F3  A2/A1  T4/T3  C4/C3  T6/T5  P4/P3  O2/O1
%
% CORRECTION 2 — FREQUENCY BAND
%   The original used power.data(1:50,...) as indices, not Hz. The band
%   index mapping in the Fig 4B code (delta 1:8, theta 10:16, alpha 16:24,
%   beta 26:60, gamma 60:100) implies 0.5 Hz per bin, which would make
%   1:50 equal to 0.5-25 Hz rather than the 1-50 Hz stated in the
%   manuscript. This script selects by ACTUAL Hz read from power.freq and
%   prints the resulting index range so the mapping can be verified
%   directly.
%
% THE TEST
%   BAND A: 8-25 Hz   - excludes drift (1-4) and theta (4-8)
%   BAND B: 1-50 Hz   - the band the manuscript claims; includes drift
%
%   Drift-band power rises from baseline by +2.92 dB in CS active and
%   +10.69 dB in HC active (5/5 subjects positive in both), and not at all
%   in either sham group. If Figure 4A's across-block modulations are
%   carried by that artifact, they should be present in BAND B and
%   substantially reduced or absent in BAND A. If the pattern is unchanged
%   between bands, Figure 4A is not a drift measurement and stands.
%
% NOTE ON INTERPRETATION
%   The drift analysis pooled electrodes irrespective of hemisphere. This
%   script preserves the ipsi/contra split, so it asks a narrower question:
%   whether the HEMISPHERIC pattern in 4A survives removal of drift, not
%   merely whether power changes.
%
% Subjects matched by NAME, never by row index (0030 sits at row 18).
%
% OUTPUT
%   fig4a_regen_<band>.png     24-panel layout, as the original
%   fig4a_ipsi_contra_<band>.png  sorted ipsi-minus-contra bar, as original
%   fig4a_regen_values.csv
%   console: ipsi-contra summary for both bands, side by side
%
% R2019b safe.

clear; clc; close all;

%% ============================ CONFIG ============================
MAT_PATH = 'C:\Users\ncr200\Downloads\data_raw\subjectData.mat';
OUT_DIR  = fullfile(pwd,'fig4a_regen');
if ~exist(OUT_DIR,'dir'); mkdir(OUT_DIR); end

BANDS = { 'A_8to25', [8 25]; 'B_1to50', [1 50] };
TIME_BINS = 9:60;              % as in the original
phases  = {'Hold','Prep','Reach'};
blocks  = {'pre','i05','i15','pos'};
blockLbl= {'BL','ES','LS','Post'};

% 9 clean homologous pairs. Midline (Fz=10, Cz=11, Pz=21) removed.
% Column 1 = right-hemisphere index, column 2 = left-hemisphere index.
pairsR = [12 13 17 20 14 18 15 19 16];   % Fp2 F8 F4 A2 T4 C4 T6 P4 O2
pairsL = [ 1  2  6  9  3  7  4  8  5];   % Fp1 F7 F3 A1 T3 C3 T5 P3 O1
pairLbl = {'Fp','F7/8','F3/4','A1/2','T3/4','C3/4','T5/6','P3/4','O1/2'};
IDX_C3C4 = 6;                            % position of the C3/C4 pair

roster = { '0003','0004','0005','0013','0015','0017','0018','0021','0042','0043', ...
           '0020','0022','0023','0024','0025','0026','0027','0028','0029','0036' };
crf_active = {'0003','0004','0005','0042','0043','0022','0024','0025','0026','0029'};
cells = {'CS','stim';'CS','sham';'HC','stim';'HC','sham'};

%% ============================ LOAD ==============================
if ~isfile(MAT_PATH); error('Not found: %s',MAT_PATH); end
S = load(MAT_PATH); sd = S.subjectData; sd_names = {sd.SubjectName};

p1 = sd(1).power;
fvec = squeeze(p1.freq(1,:,1));
fprintf('=== FREQUENCY AXIS CHECK ===\n');
fprintf('power.freq: %.3f to %.3f Hz, %d bins, spacing %.4f Hz\n', ...
    min(fvec), max(fvec), numel(fvec), median(diff(fvec)));
fprintf('Original code used indices 1:50 -> %.2f to %.2f Hz\n', ...
    fvec(1), fvec(min(50,numel(fvec))));
fprintf('Manuscript states Figure 4A covers 1-50 Hz.\n');
if abs(fvec(min(50,numel(fvec))) - 50) > 5
    fprintf('>> DISCREPANCY CONFIRMED: indices 1:50 are NOT 1-50 Hz.\n');
end
for b = 1:size(BANDS,1)
    m = fvec>=BANDS{b,2}(1) & fvec<=BANDS{b,2}(2);
    fprintf('%s (%g-%g Hz) -> indices %d:%d\n', BANDS{b,1}, ...
        BANDS{b,2}(1), BANDS{b,2}(2), find(m,1,'first'), find(m,1,'last'));
end
fprintf('\n');

vals = p1.data(:); vals = vals(isfinite(vals));
IS_DB = mean(vals<0) > 0.01;

%% ==================== EXTRACT ==================================
% P.(band){cellIdx}(subject, pair, phase, block, side)  side 1=ipsi 2=contra
P = struct(); ids = cell(size(cells,1),1);

for bi = 1:size(BANDS,1)
    bname = BANDS{bi,1};
    fmask = fvec>=BANDS{bi,2}(1) & fvec<=BANDS{bi,2}(2);

    for c = 1:size(cells,1)
        sel = {};
        for i = 1:numel(roster)
            sid = roster{i};
            mi = find(contains(sd_names,sid),1);
            if isempty(mi); continue; end
            si = sd(mi).sessioninfo;
            cond = 'sham'; if any(strcmp(sid,crf_active)); cond='stim'; end
            grp = 'HC';
            if isstruct(si)&&isfield(si,'dx')&&~isempty(si.dx)&& ...
               strcmpi(strtrim(char(string(si.dx))),'stroke'); grp='CS'; end
            if strcmp(grp,cells{c,1}) && strcmp(cond,cells{c,2}); sel{end+1}=sid; end %#ok<AGROW>
        end
        ids{c} = sel;

        A = nan(numel(sel), numel(pairsR), 3, 4, 2);
        for k = 1:numel(sel)
            mi = find(contains(sd_names,sel{k}),1);
            sl = upper(strtrim(char(string(sd(mi).sessioninfo.stimlat))));
            if strcmp(sl,'R')
                e_ipsi = pairsR; e_cont = pairsL;
            else
                e_ipsi = pairsL; e_cont = pairsR;
            end
            for e = 1:numel(e_ipsi)
                for p = 1:3
                    for t = 1:4
                        vi = sd(mi).power.data(fmask, TIME_BINS, e_ipsi(e), p, t);
                        vc = sd(mi).power.data(fmask, TIME_BINS, e_cont(e), p, t);
                        if ~IS_DB; vi = 10*log10(vi); vc = 10*log10(vc); end
                        A(k,e,p,t,1) = mean(vi(:),'omitnan');
                        A(k,e,p,t,2) = mean(vc(:),'omitnan');
                    end
                end
            end
        end
        P.(bname){c} = A;
    end
end

%% ============== CONSOLE: per-hemisphere, the quantity 4A plots ====
% IMPORTANT: Figure 4A plots the ipsilesional and contralesional traces
% SEPARATELY. It does not plot their difference. Drift therefore does NOT
% cancel in the plotted quantity: direct-current drift is present at both
% hemispheres, so it survives in each trace and only cancels when the two
% are subtracted. The drift-contamination question must be asked of the
% separate traces, which is what this section does.
fprintf('================================================================\n');
fprintf('  POWER BY HEMISPHERE (dB), 9 clean homologous pairs\n');
fprintf('  This is the quantity Figure 4A plots.\n');
fprintf('================================================================\n\n');
rows = {};
for c = 1:size(cells,1)
    fprintf('--- %s %s (n=%d) ---\n', cells{c,1},cells{c,2},numel(ids{c}));
    fprintf('%-6s %-6s %11s %11s %11s %11s\n','phase','block', ...
        'ipsi 8-25','ipsi 1-50','contra 8-25','contra 1-50');
    for p = 1:3
        for t = 1:4
            iA = mean(mean(P.A_8to25{c}(:,:,p,t,1),1,'omitnan'));
            iB = mean(mean(P.B_1to50{c}(:,:,p,t,1),1,'omitnan'));
            cA = mean(mean(P.A_8to25{c}(:,:,p,t,2),1,'omitnan'));
            cB = mean(mean(P.B_1to50{c}(:,:,p,t,2),1,'omitnan'));
            fprintf('%-6s %-6s %11.3f %11.3f %11.3f %11.3f\n', ...
                phases{p}, blockLbl{t}, iA, iB, cA, cB);
            rows(end+1,:) = {cells{c,1},cells{c,2},phases{p},blockLbl{t}, ...
                numel(ids{c}), iA, iB, cA, cB, iA-cA, iB-cB}; %#ok<AGROW>
        end
    end
    fprintf('\n');
end
writetable(cell2table(rows,'VariableNames', ...
    {'Group','Condition','Phase','Block','n', ...
     'ipsi_8to25','ipsi_1to50','contra_8to25','contra_1to50', ...
     'ipsi_minus_contra_8to25','ipsi_minus_contra_1to50'}), ...
    fullfile(OUT_DIR,'fig4a_regen_values.csv'));

%% ============== THE TEST: does drift inflate 4A's traces? ========
% Across-block modulation is computed on each hemisphere SEPARATELY, since
% that is what the figure displays. If the 1-50 Hz band (which contains the
% 1-4 Hz drift range) shows markedly larger modulation than 8-25 Hz (which
% excludes drift and theta), then drift is inflating the traces in 4A.
fprintf('================================================================\n');
fprintf('  ACROSS-BLOCK MODULATION (max-min over blocks), BY HEMISPHERE\n');
fprintf('================================================================\n');
fprintf('Ratio >> 1 : modulation shrinks when drift is excluded, i.e. the\n');
fprintf('             trace in Figure 4A is substantially drift.\n');
fprintf('Ratio ~ 1  : the trace is independent of drift.\n');
fprintf('The ipsi-contra column is retained for reference; drift largely\n');
fprintf('cancels there, which is why it was uninformative about 4A.\n\n');
fprintf('%-14s %-6s %-7s %9s %9s %8s\n', ...
    'cell','phase','measure','8-25 Hz','1-50 Hz','ratio');
mrows = {};
for c = 1:size(cells,1)
    for p = 1:3
        for meas = 1:3
            vA = nan(1,4); vB = nan(1,4);
            for t = 1:4
                switch meas
                    case 1  % ipsi
                        vA(t) = mean(mean(P.A_8to25{c}(:,:,p,t,1),1,'omitnan'));
                        vB(t) = mean(mean(P.B_1to50{c}(:,:,p,t,1),1,'omitnan'));
                    case 2  % contra
                        vA(t) = mean(mean(P.A_8to25{c}(:,:,p,t,2),1,'omitnan'));
                        vB(t) = mean(mean(P.B_1to50{c}(:,:,p,t,2),1,'omitnan'));
                    case 3  % difference
                        vA(t) = mean(mean(P.A_8to25{c}(:,:,p,t,1),1,'omitnan') - ...
                                     mean(P.A_8to25{c}(:,:,p,t,2),1,'omitnan'));
                        vB(t) = mean(mean(P.B_1to50{c}(:,:,p,t,1),1,'omitnan') - ...
                                     mean(P.B_1to50{c}(:,:,p,t,2),1,'omitnan'));
                end
            end
            rA = max(vA)-min(vA); rB = max(vB)-min(vB);
            mn = {'ipsi','contra','diff'};
            fprintf('%-14s %-6s %-7s %9.3f %9.3f %8.2f\n', ...
                [cells{c,1} ' ' cells{c,2}], phases{p}, mn{meas}, rA, rB, rB/max(rA,eps));
            mrows(end+1,:) = {cells{c,1},cells{c,2},phases{p},mn{meas}, ...
                rA,rB,rB/max(rA,eps)}; %#ok<AGROW>
        end
    end
end
writetable(cell2table(mrows,'VariableNames', ...
    {'Group','Condition','Phase','Measure','modulation_8to25', ...
     'modulation_1to50','ratio'}), ...
    fullfile(OUT_DIR,'fig4a_modulation_by_hemisphere.csv'));

MR = cell2table(mrows,'VariableNames', ...
    {'Group','Condition','Phase','Measure','modulation_8to25', ...
     'modulation_1to50','ratio'});
fprintf('\n=== SUMMARY: mean ratio by measure ===\n');
for meas = {'ipsi','contra','diff'}
    m = strcmp(MR.Measure,meas{1});
    fprintf('  %-7s mean ratio %.2f  (range %.2f - %.2f)\n', meas{1}, ...
        mean(MR.ratio(m)), min(MR.ratio(m)), max(MR.ratio(m)));
end
fprintf('\n=== The decisive cells: actively stimulated groups ===\n');
for c = [1 3]   % CS stim, HC stim
    for meas = {'ipsi','contra'}
        m = strcmp(MR.Group,cells{c,1}) & strcmp(MR.Condition,cells{c,2}) & ...
            strcmp(MR.Measure,meas{1});
        fprintf('  %s %s %-7s mean ratio %.2f\n', cells{c,1}, cells{c,2}, ...
            meas{1}, mean(MR.ratio(m)));
    end
end
fprintf(['\nHC stim has the largest drift increase (+10.69 dB baseline to LS).\n' ...
         'If drift inflates the traces in Figure 4A, HC stim ipsi should show\n' ...
         'the largest ratio of any cell. If its ratio is near 1, Figure 4A is\n' ...
         'not a drift measurement and the full band can be reported.\n\n']);

%% ==================== FIGURES ==================================
for bi = 1:size(BANDS,1)
    bname = BANDS{bi,1};
    fh = figure('Position',[36 40 1391 796],'Visible','off');
    sp = 0;
    for c = 1:size(cells,1)
        for p = 1:3
            for side = 1:2
                sp = sp + 1;
                subplot(4,6,sp); hold on
                A = P.(bname){c};
                M = squeeze(mean(A(:,:,p,:,side),1,'omitnan'));   % pair x block
                for e = 1:size(M,1)
                    plot(1:4, M(e,:), 'Color',[0.7 0.7 0.7]);
                end
                plot(1:4, M(IDX_C3C4,:), 'LineWidth',2, ...
                    'Color', tern(side==1,'b','r'));
                set(gca,'XTick',1:4,'XTickLabel',blockLbl,'FontSize',7);
                grid on; xlim([0.8 4.2]);
                title(sprintf('%s %s %s %s', cells{c,1}, cells{c,2}, ...
                    tern(side==1,'ipsi','contra'), phases{p}), 'FontSize',7);
            end
        end
    end
    sgt(sprintf('Figure 4A regenerated: %g-%g Hz, 9 clean homologous pairs (C3/C4 bold)', ...
        BANDS{bi,2}(1), BANDS{bi,2}(2)));
    print(fh, fullfile(OUT_DIR,sprintf('fig4a_regen_%s.png',bname)),'-dpng','-r150');
    close(fh);

    % sorted ipsi-minus-contra bar, summed over groups/phases as original
    tot_i = zeros(1,numel(pairsR)); tot_c = zeros(1,numel(pairsR));
    for c = 1:size(cells,1)
        A = P.(bname){c};
        for p = 1:3
            Mi = squeeze(mean(A(:,:,p,:,1),1,'omitnan'));
            Mc = squeeze(mean(A(:,:,p,:,2),1,'omitnan'));
            tot_i = tot_i + (max(Mi,[],2)-min(Mi,[],2))';
            tot_c = tot_c + (max(Mc,[],2)-min(Mc,[],2))';
        end
    end
    dd = tot_i - tot_c;
    [dds, ord] = sort(dd,'descend');
    fh = figure('Position',[100 100 620 380],'Visible','off');
    bar(dds); grid on;
    set(gca,'XTickLabel',pairLbl(ord),'XTickLabelRotation',45);
    ylabel('ipsi - contra (summed across-block range, dB)');
    title(sprintf('%g-%g Hz', BANDS{bi,2}(1), BANDS{bi,2}(2)));
    print(fh, fullfile(OUT_DIR,sprintf('fig4a_ipsi_contra_%s.png',bname)),'-dpng','-r150');
    close(fh);
end

fprintf('Wrote %s\n', OUT_DIR);

%% ==================== LOCAL FUNCTIONS =========================
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
