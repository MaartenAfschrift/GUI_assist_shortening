# Post-export checklist: App Designer (2025b) → MATLAB 2018

Every time you re-export from App Designer, search the new `.m` file for these and fix them in `createComponents`. Takes ~2 minutes.

## 1. Remove the `Theme` line
Search for:
```matlab
app.UIFigure.Theme = 'light';
```
Delete it or comment it out. This property doesn't exist in R2018 uifigure — and isn't needed, since `uifigure` is light-themed by default there anyway.

## 2. Guard the axes `Toolbar` lines
Search for `.Toolbar.Visible = 'off';` (one line per `UIAxes` you have). Wrap each in try/catch so it degrades gracefully instead of crashing `createComponents` if unsupported on your release:
```matlab
try %#ok<TRYNC>
    app.SomeAxes.Toolbar.Visible = 'off';
catch
end
```

## 3. Sanity-check any component references you touched by hand
If you renamed a component in App Designer, make sure every `app.ComponentName` reference in your own custom code (callbacks, helper methods, `startupFcn`) matches the property list at the top of the file exactly. App Designer keeps these in sync automatically — but if you ever typed a name by hand (like the `UploadMuscleParamsButton` typo), it won't be caught until runtime.

## Optional: quick automated check
Before opening in MATLAB 2018, grep the new export for both known offenders:
```bash
grep -n "\.Theme\s*=" Assist_Shortening_GUI_exported.m
grep -n "\.Toolbar\.Visible" Assist_Shortening_GUI_exported.m
```
Anything these return needs step 1 or 2 applied.

---
That's it — in this app those are the only two forward-only features App Designer 2025b currently emits. If a future App Designer version starts using something else new (e.g. new component types, `arguments` blocks, newer string functions), add it to this list.
