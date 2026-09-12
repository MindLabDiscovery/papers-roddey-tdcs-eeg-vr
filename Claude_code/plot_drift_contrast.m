%% plot_drift_contrast.m
%
% PURPOSE
%   Demonstrate, in one panel per group, that contrasting late against
%   early stimulation removes the direct-current drift artifact.
%
%   Drift-band power rises sharply when either stimulation timepoint is
%   compared against baseline. It does not rise when late stimulation is
%   compared against early, because current flows in both periods and the
%   stationary artifact subtracts out. Plotting all four contrasts on one
%   axis makes this visible directly rather than requiring the reader to
%   compare two separate figures.
%
%   Four bars per group:
%       ES - BL    early stimulation minus baseline
%       LS - BL    late stimulation minus baseline
%       Post - BL  post-stimulation minus baseline (recovery check)
%       LS - ES    the artifact-controlled contrast
%
%   Expected pattern in the ACTIVE groups: bars 1 and 2 large and positive,
%   bar 3 near zero (drift resolves once current stops), bar 4 near zero
%   (the contrast removes it). Sham groups flat throughout.
%
% INPUT
%   drift_values.csv, written by plot_drift_figure.m. Uses the drift band
%   only; the file also contains theta, alpha, beta and gamma.
%
% OUTPUT
%   fig_drift_contrast.png / .svg
%   drift_contrast_values.csv   per-group means, SD and one-sample tests
%
% R2019b safe.

clear; clc; close all;

%% ============================ CONFIG ============================
CSV_PATH = fullfile(pwd,'drift_out','drift_values.csv');
if ~isfile(CSV_PATH); CSV_PATH = fullfile(pwd,'drift_values.csv'); end
OUT_DIR  = fullfile(pwd,'drift_out');
if ~exist(OUT_DIR,'dir'); mkdir(OUT_DIR); end

BAND  = 'drift';
cells = {'CS','active';'CS','sham';'HC','active';'HC','sham'};
cellLbl = {'Chronic stroke, active','Chronic stroke, sham', ...
           'Healthy control, active','Healthy control, sham'};
barLbl  = {'ES - BL','LS - BL','Post - BL','LS - ES'};
% first three are versus baseline (artifact present), fourth is the
% artifact-controlled contrast; coloured to make that distinction obvious
barCol  = [0.80 0.25 0.20; 0.80 0.25 0.20; 0.65 0.65 0.65; 0.15 0.35 0.70];

%% ============================ LOAD ==============================
if ~isfile(CSV_PATH)
    error(['%s not found. Run plot_drift_figure.m first.'], CSV_PATH);
end
T = readtable(CSV_PATH,'Delimiter',',');
for v = {'Group','Condition','Band'}
    if iscell(T.(v{1})) || isstring(T.(v{1})); T.(v{1}) = cellstr(string(T.(v{1}))); end
end
T = T(strcmpi(T.Band,BAND),:);
fprintf('Loaded %d rows for band "%s" (%d subjects)\n\n', height(T), BAND, ...
    numel(unique(T.SubjectID)));

%% ==================== COMPUTE ==================================
% Per subject: four contrasts from the four block means already in the file
D = cell(size(cells,1),1);
for c = 1:size(cells,1)
    m = strcmpi(T.Group,cells{c,1}) & strcmpi(T.Condition,cells{c,2});
    s = T(m,:);
    D{c} = [ s.ES - s.BL, s.LS - s.BL, s.Post - s.BL, s.LS - s.ES ];
end

rows = {};
fprintf('=================================================================\n');
fprintf('  DRIFT-BAND CHANGE (dB), by contrast\n');
fprintf('=================================================================\n');
fprintf('If the LS-ES contrast removes the artifact, the fourth column is\n');
fprintf('near zero while the first two are large in the active groups.\n\n');
fprintf('%-26s %12s %12s %12s %12s\n', 'group', barLbl{:});
for c = 1:size(cells,1)
    v = D{c};
    fprintf('%-26s', cellLbl{c});
    for k = 1:4
        fprintf(' %+7.2f±%-4.2f', mean(v(:,k),'omitnan'), std(v(:,k),'omitnan'));
    end
    fprintf('\n');
    for k = 1:4
        x = v(:,k); x = x(isfinite(x));
        [tv,pv] = tt1(x);
        rows(end+1,:) = {cellLbl{c}, barLbl{k}, numel(x), mean(x), std(x), ...
            sum(x>0), tv, pv}; %#ok<AGROW>
    end
end
writetable(cell2table(rows,'VariableNames', ...
    {'Group','Contrast','n','mean_dB','sd_dB','n_positive','t','p'}), ...
    fullfile(OUT_DIR,'drift_contrast_values.csv'));

fprintf('\n--- one-sample t versus zero, and sign consistency ---\n');
fprintf('%-26s %-10s %9s %8s %10s\n','group','contrast','mean','n pos','p');
for i = 1:size(rows,1)
    fprintf('%-26s %-10s %+9.2f %5d/%-2d %10.4f%s\n', rows{i,1}, rows{i,2}, ...
        rows{i,4}, rows{i,6}, rows{i,3}, rows{i,8}, ...
        tern(isfinite(rows{i,8}) && rows{i,8}<0.05,' *',''));
end

%% ==================== FIGURE ===================================
allv = cell2mat(cellfun(@(v) v(:), D, 'UniformOutput',false));
allv = allv(isfinite(allv));
pad  = 0.12*range(allv);
yl   = [min(allv)-pad, max(allv)+pad];

fh = figure('Position',[40 40 1150 380],'Visible','off');
for c = 1:size(cells,1)
    v = D{c};
    subplot(1,4,c); hold on
    mu = mean(v,1,'omitnan');
    se = arrayfun(@(k) sem(v(:,k)), 1:4);
    for k = 1:4
        bar(k, mu(k), 0.68, 'FaceColor', barCol(k,:), 'EdgeColor','none');
    end
    errorbar(1:4, mu, se, '.k', 'LineWidth',1.1);
    % individual participants
    for k = 1:4
        x = v(:,k);
        plot(k + 0.09*randn(size(x)), x, 'o', 'MarkerSize',3.5, ...
            'MarkerEdgeColor',[0.25 0.25 0.25], 'HandleVisibility','off');
    end
    plot([0.4 4.6],[0 0],'k-','LineWidth',0.8,'HandleVisibility','off');
    % mark the artifact-controlled contrast
    yy = yl(1) + 0.04*range(yl);
    plot([3.55 3.55],yl,'k:','LineWidth',1,'HandleVisibility','off');
    ylim(yl); xlim([0.4 4.6]);
    set(gca,'XTick',1:4,'XTickLabel',barLbl,'XTickLabelRotation',35,'FontSize',8);
    grid on; box off
    title(cellLbl{c},'FontSize',9);
    if c==1; ylabel(sprintf('%s-band change (dB)',BAND),'FontSize',9); end
end
sgt(['Drift-band change by contrast. Bars left of the dotted line compare ' ...
     'against baseline; the rightmost is the artifact-controlled contrast.']);
savefig_both(fh, fullfile(OUT_DIR,'fig_drift_contrast.png'));

fprintf('\nWrote %s\n', OUT_DIR);
fprintf(['\nREAD: in the ACTIVE groups the first two bars should be large and\n' ...
         'positive and the fourth near zero. That is the demonstration that\n' ...
         'the early-versus-late contrast removes the drift artifact. If the\n' ...
         'fourth bar is also large, the artifact is not stationary across the\n' ...
         'stimulation period and the contrast does not remove it.\n']);

%% ==================== LOCAL FUNCTIONS =========================
function [t,p] = tt1(x)
x = x(isfinite(x)); n = numel(x);
if n < 2 || std(x)==0; t=NaN; p=NaN; return; end
t = mean(x)/(std(x)/sqrt(n));
if exist('ttest','file')==2
    [~,p] = ttest(x);
else
    p = 2*(1 - 0.5*(1+erf(abs(t)/sqrt(2))));
end
end

function s = sem(x)
x = x(isfinite(x));
if numel(x)<2; s=0; else; s=std(x)/sqrt(numel(x)); end
end

function sgt(txt)
if exist('sgtitle','file'); sgtitle(txt,'FontSize',9);
else
    annotation('textbox',[0 0.94 1 0.06],'String',txt,'EdgeColor','none', ...
        'HorizontalAlignment','center','FontWeight','bold');
end
end

function savefig_both(fh, pngpath)
print(fh, pngpath, '-dpng','-r150');
[d,n,~] = fileparts(pngpath);
try
    print(fh, fullfile(d,[n '.svg']), '-dsvg','-painters');
    fprintf('  wrote %s and .svg\n', pngpath);
catch ME
    fprintf('  wrote %s (SVG failed: %s)\n', pngpath, ME.message);
end
close(fh);
end

function out = tern(c,a,b)
if c; out=a; else; out=b; end
end
