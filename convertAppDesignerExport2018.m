function convertAppDesignerExport2018(inputFile, outputFile)
%CONVERTAPPDESIGNEREXPORT2018 Patch an App Designer export for MATLAB R2018.
%
%   convertAppDesignerExport2018(inputFile) reads the .m file exported by
%   App Designer, applies the known R2018 compatibility fixes, and writes
%   the result to '<name>_MATLAB2018.m' in the same folder.
%
%   convertAppDesignerExport2018(inputFile, outputFile) writes to a
%   specific path instead (pass the same path as inputFile to overwrite).
%
%   Fixes applied:
%     1. Comments out "app.UIFigure.Theme = ...;" — the Theme property
%        does not exist on pre-R2025 uifigure.
%     2. Wraps every "*.Toolbar.Visible = 'off';" line in try/catch —
%        the axes Toolbar property may not exist on older releases.
%     3. Scans all "app.<name>" references and flags any that don't
%        match a declared property or method name (catches typos, e.g.
%        the UploadMuscleParamsButton bug) as warnings. Nothing is
%        auto-fixed for #3 — you still need to fix those by hand, since
%        the correct target name can't be guessed reliably.
%
%   Example:
%     convertAppDesignerExport2018('Assist_Shortening_GUI_exported.m');

if nargin < 2 || isempty(outputFile)
    [p, n, e] = fileparts(inputFile);
    outputFile = fullfile(p, [n '_MATLAB2018' e]);
end

txt = fileread(inputFile);

%% 1. Comment out the Theme line
themePattern = '(?m)^([ \t]*)(app\.UIFigure\.Theme\s*=\s*[^;]*;)[ \t]*$';
nTheme = numel(regexp(txt, themePattern, 'match'));
txt = regexprep(txt, themePattern, ...
    '$1% $2 % [AUTO-2018] removed: Theme not supported pre-R2025 uifigure');

%% 2. Guard every Toolbar.Visible line in try/catch
toolbarPattern = '(?m)^([ \t]*)(app\.\w+\.Toolbar\.Visible\s*=\s*''off'';)[ \t]*$';
nToolbar = numel(regexp(txt, toolbarPattern, 'match'));
txt = regexprep(txt, toolbarPattern, [ ...
    '$1try %#ok<TRYNC> % [AUTO-2018] guarded: Toolbar may not exist pre-R2018b\n' ...
    '$1    $2\n' ...
    '$1catch\n' ...
    '$1end']);

%% 3. Flag app.<name> references with no matching property/method
declared = [localGetPropertyNames(txt), localGetMethodNames(txt)];
usedTok = regexp(txt, 'app\.([A-Za-z_]\w*)', 'tokens');
used = unique(cellfun(@(c) c{1}, usedTok, 'UniformOutput', false));
unknownNames = setdiff(used, declared);

%% Write result
fid = fopen(outputFile, 'w');
if fid == -1
    error('convertAppDesignerExport2018:writeFailed', ...
        'Could not open output file: %s', outputFile);
end
fwrite(fid, txt);
fclose(fid);

%% Report
fprintf('Wrote: %s\n', outputFile);
fprintf('  Theme lines commented out: %d\n', nTheme);
fprintf('  Toolbar lines guarded:     %d\n', nToolbar);
if isempty(unknownNames)
    fprintf('  No unrecognized app.<name> references found.\n');
else
    fprintf(2, '  WARNING: app.<name> references with no matching property/method (likely typos):\n');
    for i = 1:numel(unknownNames)
        fprintf(2, '    app.%s\n', unknownNames{i});
    end
end

end

function names = localGetPropertyNames(txt)
% Extract identifiers declared inside any "properties ... end" block.
blocks = regexp(txt, 'properties[ \t]*(?:\([^)]*\))?(.*?)\n[ \t]*end', 'tokens', 'dotall');
names = {};
for i = 1:numel(blocks)
    lines = strsplit(blocks{i}{1}, newline);
    for j = 1:numel(lines)
        tok = regexp(lines{j}, '^[ \t]*([A-Za-z_]\w*)\b', 'tokens', 'once');
        if ~isempty(tok)
            names{end+1} = tok{1}; %#ok<AGROW>
        end
    end
end
names = unique(names);
end

function names = localGetMethodNames(txt)
% Extract identifiers declared via "function ... name(app, ...)".
toks = regexp(txt, '(?m)^[ \t]*function\s+(?:\[[^\]]*\]\s*=\s*|[\w.]+\s*=\s*)?([A-Za-z_]\w*)\s*\(', 'tokens');
names = unique(cellfun(@(c) c{1}, toks, 'UniformOutput', false));
end
