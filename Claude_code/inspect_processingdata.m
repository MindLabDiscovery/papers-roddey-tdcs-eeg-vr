function inspect_processingdata(matfile)
% INSPECT_PROCESSINGDATA
%
% Reports where, if anywhere, processingData is stored in an EEGlab_Total.mat
% file, and what the top-level structure looks like. Run this before
% export_cleaning_psd to find out whether the intermediate pipeline stages
% were retained and where they live.
%
% USAGE
%   inspect_processingdata('D:\...\pro00087153_0004\analysis\EEGlab\EEGlab_Total.mat')
%
%   Also works on a stand-alone pipeline.mat:
%   inspect_processingdata('D:\...\PreprocessingCheck\pipeline.mat')

if exist(matfile,'file')~=2
    error('Not found: %s', matfile);
end

fprintf('\n================================================================\n');
fprintf('  %s\n', matfile);
d = dir(matfile);
fprintf('  %.1f MB, modified %s\n', d.bytes/1e6, d.date);
fprintf('================================================================\n\n');

% --- what variables does the file contain? ---
info = whos('-file', matfile);
fprintf('TOP-LEVEL VARIABLES:\n');
for i = 1:numel(info)
    fprintf('  %-22s %-10s %12.1f MB\n', info(i).name, info(i).class, ...
        info(i).bytes/1e6);
end
fprintf('\n');

% --- load each and walk it ---
for i = 1:numel(info)
    nm = info(i).name;
    fprintf('----------------------------------------------------------------\n');
    fprintf('  %s\n', nm);
    fprintf('----------------------------------------------------------------\n');
    S = load(matfile, nm);
    v = S.(nm);
    walk(v, ['  ' nm], 0);
    clear S v
    fprintf('\n');
end

fprintf('================================================================\n');
fprintf('If processingData appears above, note the full path to it and\n');
fprintf('report that path; export_cleaning_psd can then be pointed at it.\n');
fprintf('If it does not appear, the intermediate stages were not retained\n');
fprintf('in this file (opt.icarem.save_procPipeline was false for this run).\n');
fprintf('================================================================\n');

end

% =========================================================================
function walk(v, path, depth)
% Recursive structure walk, stopping at depth 4 or on non-struct leaves.
MAXDEPTH = 4;

if depth > MAXDEPTH
    return
end

if iscell(v)
    fprintf('%s  {cell %s}\n', path, mat2str(size(v)));
    if ~isempty(v) && depth < MAXDEPTH
        walk(v{1}, [path '{1}'], depth+1);
    end
    return
end

if ~isstruct(v)
    return
end

if numel(v) > 1
    fprintf('%s  [struct array %s]\n', path, mat2str(size(v)));
    v = v(1);
    path = [path '(1)'];
end

fn = fieldnames(v);

% flag the field we are looking for
hit = fn(strcmpi(fn,'processingData'));
if ~isempty(hit)
    pd = v.(hit{1});
    fprintf('%s.%s   <<<<<< FOUND', path, hit{1});
    if iscell(pd)
        fprintf('  (cell, %d stages)\n', numel(pd));
        for k = 1:numel(pd)
            if isstruct(pd{k}) && isfield(pd{k},'details')
                dt = pd{k}.details;
                if iscell(dt); dt = dt{1}; end
                sz = '';
                if isfield(pd{k},'data')
                    dd = pd{k}.data;
                    if iscell(dd); sz = sprintf('cell{%d}, first %s', ...
                            numel(dd), mat2str(size(dd{1})));
                    else; sz = mat2str(size(dd)); end
                end
                fprintf('      stage %d: %-42s %s\n', k, char(dt), sz);
            else
                fprintf('      stage %d: (no details field)\n', k);
            end
        end
    else
        fprintf('  (class %s)\n', class(pd));
    end
end

% recurse into remaining fields
for i = 1:numel(fn)
    if strcmpi(fn{i},'processingData'); continue; end
    val = v.(fn{i});
    if isstruct(val) || iscell(val)
        % skip the bulky EEG payload fields
        if any(strcmpi(fn{i},{'data','chanlocs','event','epoch','icaweights', ...
                              'icawinv','icasphere','times','urevent','power'}))
            continue
        end
        walk(val, sprintf('%s.%s', path, fn{i}), depth+1);
    end
end

% at shallow depth, list plain fields so the layout is visible
if depth <= 1
    plain = {};
    for i = 1:numel(fn)
        if ~isstruct(v.(fn{i})) && ~iscell(v.(fn{i}))
            plain{end+1} = fn{i}; %#ok<AGROW>
        end
    end
    if ~isempty(plain)
        fprintf('%s  fields: %s\n', path, strjoin(plain(1:min(12,numel(plain))), ', '));
    end
end
end
