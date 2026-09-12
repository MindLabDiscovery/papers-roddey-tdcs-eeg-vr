function plot_anodal_spectrograms(protocolfolder, outDir)
% PLOT_ANODAL_SPECTROGRAMS
%
% Generates one spectrogram per chronic stroke ACTIVE STIMULATION subject for
% that subject's ANODAL channel (C3 or C4, whichever carried the anode),
% across the full session: BL -> ES -> LS -> Post.
%
% PURPOSE
%   Test visually whether blocks in which the anodal channel was interpolated
%   are spectrally distinguishable from blocks in which it was physically
%   measured. Subjects 0003 and 0004 had the anodal channel interpolated at ES
%   and LS only; 0005, 0042 and 0043 were never interpolated. If interpolation
%   leaves a spectral signature, 0003 and 0004 should show a visible change at
%   the ES/LS boundaries that the other three do not.
%
%   This is a check on an assumption, not a confirmatory analysis. Interpret
%   accordingly - a null result here does not prove interpolation is harmless,
%   only that it is not grossly visible.
%
% ANODE ASSIGNMENT
%   Anode is contralateral to the affected (VR) hand: right hand -> C3,
%   left hand -> C4. Taken from Table 1.
%
% USAGE
%   plot_anodal_spectrograms('D:\...\data_raw','C:\Users\ncr200\Downloads\spectrograms')
%
% OUTPUT
%   One PNG per subject in outDir, plus a combined PSD comparison figure.
%   Requires the Signal Processing Toolbox (spectrogram, pwelch).

if nargin < 2 || isempty(outDir)
    outDir = fullfile(pwd,'spectrograms');
end
if ~exist(outDir,'dir'), mkdir(outDir); end

% ---- CS active stimulation subjects, with anode side ---------------------
% subject            anode  VR hand (Table 1)
subjects = {
 'pro00087153_0003', 'C3', 'R'
 'pro00087153_0004', 'C3', 'R'
 'pro00087153_0005', 'C4', 'L'
 'pro00087153_0042', 'C4', 'L'
 'pro00087153_0043', 'C3', 'R'
};

blockNames  = {'t1','t2','t3','t4'};
blockLabels = {'BL','ES','LS','Post'};

FMAX = 100;      % display ceiling (Nyquist is 128 Hz at 256 Hz)
GAMMA = [30 50]; % band used in the manuscript

psdStore = struct();

for s = 1:size(subjects,1)

    subject   = subjects{s,1};
    anodeChan = subjects{s,2};
    sid       = subject(end-3:end);

    totalFile = fullfile(protocolfolder,subject,'analysis','EEGlab','EEGlab_Total.mat');
    if exist(totalFile,'file')~=2
        fprintf('  %s : MISSING EEGlab_Total.mat -- skipped\n', subject); continue
    end
    fprintf('  %s (anode %s, %s hand) ... ', subject, anodeChan, subjects{s,3});

    try
        S = load(totalFile,'eegevents_tfa');
        if isfield(S,'eegevents_tfa'), ev = S.eegevents_tfa;
        else, S = load(totalFile,'eegevents_ft'); ev = S.eegevents_ft; end
        clear S
    catch ME
        fprintf('LOAD FAILED (%s)\n',ME.message); continue
    end

    % ---- assemble the session for the anodal channel --------------------
    sig        = [];      % concatenated signal
    bounds     = [];      % sample index at each block boundary
    blockInterp = false(1,numel(blockNames));
    blockPresent = false(1,numel(blockNames));
    srate = NaN;

    for b = 1:numel(blockNames)
        if ~isfield(ev.trials,blockNames{b}), continue; end
        wk = ev.trials.(blockNames{b});

        blockSig = [];
        for p = 1:min(3,size(wk,1))
            peeg = wk(p,:);
            if isempty(peeg) || ~isfield(peeg,'setname') || isempty(peeg.setname), continue; end

            lbls = {peeg.chanlocs.labels};
            ich  = find(strcmpi(lbls,anodeChan),1);
            if isempty(ich), continue; end

            srate = peeg.srate;

            % interpolation status (block-level, inherited by phases)
            if isfield(peeg,'badChannels') && isfield(peeg.badChannels,'channels')
                bc = peeg.badChannels.channels;
                if ~any(isnan(bc(:))) && ismember(ich, bc(:)')
                    blockInterp(b) = true;
                end
            end

            d = double(squeeze(peeg.data(ich,:,:)));   % time x epochs
            blockSig = [blockSig; d(:)];               %#ok<AGROW> concatenate epochs
        end

        if ~isempty(blockSig)
            blockPresent(b) = true;
            sig = [sig; blockSig];          %#ok<AGROW>
            bounds(end+1) = numel(sig);     %#ok<AGROW>
            % store per-block PSD
            [pxx,f] = pwelch(blockSig - mean(blockSig), hamming(srate), srate/2, [], srate);
            psdStore.(['s' sid]).(blockLabels{b}) = struct('pxx',pxx,'f',f, ...
                                                           'interp',blockInterp(b));
        end
    end
    clear ev

    if isempty(sig)
        fprintf('no data for %s\n', anodeChan); continue
    end

    % ---- spectrogram ----------------------------------------------------
    win  = round(srate);           % 1 s window
    nov  = round(srate*0.5);       % 50% overlap
    nfft = 2^nextpow2(srate*2);    % ~0.5 Hz resolution

    fh = figure('Color','w','Position',[100 100 1150 620],'Visible','off');

    ax1 = subplot(3,1,[1 2]);
    [~,F,T,P] = spectrogram(sig - mean(sig), win, nov, nfft, srate);
    keep = F <= FMAX;
    Pdb  = 10*log10(P(keep,:) + eps);
    imagesc(T, F(keep), Pdb); axis xy
    cl = prctile_compat(Pdb(:),[5 99]);
    caxis(cl); colormap(ax1, parula);
    cb = colorbar; cb.Label.String = 'Power (dB)';
    ylabel('Frequency (Hz)'); xlabel('Concatenated session time (s)');

    hold on
    % block boundaries and labels
    tb = bounds / srate;
    prev = 0;
    for b = 1:numel(tb)
        if b < numel(tb)
            plot([tb(b) tb(b)],[0 FMAX],'w-','LineWidth',2);
        end
        mid = (prev + tb(b))/2;
        idx = find(blockPresent); lbl = blockLabels{idx(b)};
        flag = ''; if blockInterp(idx(b)), flag = ' *INTERP*'; end
        text(mid, FMAX*0.93, [lbl flag], 'Color','w','FontWeight','bold', ...
             'HorizontalAlignment','center','FontSize',11);
        prev = tb(b);
    end
    % gamma band markers
    plot(xlim,[GAMMA(1) GAMMA(1)],'w--','LineWidth',0.75);
    plot(xlim,[GAMMA(2) GAMMA(2)],'w--','LineWidth',0.75);
    hold off

    interpBlocks = blockLabels(blockInterp & blockPresent);
    if isempty(interpBlocks), istr = 'none'; else, istr = strjoin(interpBlocks,', '); end
    title(sprintf(['Subject %s  |  CS active stim  |  anodal channel %s  |  ' ...
                   'interpolated in: %s'], sid, anodeChan, istr), ...
          'FontSize',13,'FontWeight','bold','Interpreter','none');

    % ---- PSD per block --------------------------------------------------
    subplot(3,1,3); hold on
    cols = lines(4); lg = {};
    idx = find(blockPresent);
    for b = 1:numel(idx)
        bl = blockLabels{idx(b)};
        if ~isfield(psdStore.(['s' sid]), bl), continue; end
        q = psdStore.(['s' sid]).(bl);
        ls = '-'; if q.interp, ls = '--'; end
        plot(q.f, 10*log10(q.pxx+eps), ls, 'Color', cols(b,:), 'LineWidth', 1.6);
        lg{end+1} = [bl, repmat(' (interp)',1,q.interp)]; %#ok<AGROW>
    end
    xlim([1 FMAX]); grid on
    yl = ylim;
    patch([GAMMA(1) GAMMA(2) GAMMA(2) GAMMA(1)],[yl(1) yl(1) yl(2) yl(2)], ...
          [0.85 0.85 0.85],'FaceAlpha',0.35,'EdgeColor','none');
    set(gca,'Children',flipud(get(gca,'Children')));
    xlabel('Frequency (Hz)'); ylabel('PSD (dB/Hz)');
    legend(lg,'Location','northeast','Box','off');
    title('Power spectral density by block (dashed = anodal channel interpolated; shaded = gamma 30-50 Hz)', ...
          'FontSize',10,'FontWeight','normal');
    hold off

    outFile = fullfile(outDir, sprintf('spectrogram_CSstim_%s_%s.png', sid, anodeChan));
    savefig_compat(fh, outFile);
    close(fh);
    fprintf('saved %s\n', outFile);
end

% =========================================================================
% Combined PSD comparison: interpolated vs measured blocks, all subjects
% =========================================================================
fh = figure('Color','w','Position',[100 100 1000 420],'Visible','off');
subplot(1,2,1); hold on; title('Anodal channel PSD — blocks MEASURED');
subplot(1,2,2); hold on; title('Anodal channel PSD — blocks INTERPOLATED');

flds = fieldnames(psdStore);
for i = 1:numel(flds)
    bl = fieldnames(psdStore.(flds{i}));
    for j = 1:numel(bl)
        q = psdStore.(flds{i}).(bl{j});
        subplot(1,2, 1 + double(q.interp));
        plot(q.f, 10*log10(q.pxx+eps), 'LineWidth',1.2);
    end
end
for k = 1:2
    subplot(1,2,k); xlim([1 FMAX]); grid on
    xlabel('Frequency (Hz)'); ylabel('PSD (dB/Hz)');
end
outFile = fullfile(outDir,'PSD_measured_vs_interpolated.png');
savefig_compat(fh, outFile); close(fh);
fprintf('\nCombined comparison saved: %s\n', outFile);

fprintf('\nDone. %d figures in %s\n', size(subjects,1)+1, outDir);

end

% =========================================================================
function savefig_compat(fh, outFile)
% exportgraphics requires R2020a+. Fall back to print() on older releases.
try
    if exist('exportgraphics','file') == 2 || exist('exportgraphics','builtin') == 5
        exportgraphics(fh, outFile, 'Resolution', 150);
    else
        error('no exportgraphics');
    end
catch
    set(fh,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
    print(fh, outFile, '-dpng', '-r150');
end
end

function y = prctile_compat(x, p)
% prctile requires the Statistics Toolbox. Fall back to interpolated quantiles.
if exist('prctile','file') == 2
    y = prctile(x, p); return
end
x = sort(x(:)); n = numel(x);
if n == 0, y = nan(size(p)); return; end
pos = max(1, min(n, (p(:)/100)*n + 0.5));
lo = floor(pos); hi = ceil(pos); frac = pos - lo;
y = x(lo).*(1-frac) + x(hi).*frac;
y = reshape(y, size(p));
end
