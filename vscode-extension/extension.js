// ajnotes-typst helper for VS Code: preview or export the whole document a file
// belongs to.
//
// Tinymist's preview and PDF export always act on the file in the active editor,
// so from a lecture they'd show or export that lecture alone — no title page,
// header or section numbers, and a stray lec_NN.pdf. These two commands act on
// the document's main.typ instead, then return you to the file you were editing:
//
//   ajnotes: Preview Document     (Cmd/Ctrl+K V in Typst files)
//   ajnotes: Export Document PDF  (Cmd/Ctrl+Alt+B, as LaTeX Workshop's build)

const vscode = require('vscode');
const fs = require('fs');
const path = require('path');

// The main.typ that `file` belongs to: the nearest one at or above its folder —
// notes/main.typ for a lecture or a notes figure, exercises/ex_NN/main.typ for a
// sheet. A course's course.typ (which sits above both) maps to its notes.
function mainFor(file) {
  if (path.basename(file) === 'course.typ') {
    const notes = path.join(path.dirname(file), 'notes', 'main.typ');
    return fs.existsSync(notes) ? notes : null;
  }
  let dir = path.dirname(file);
  for (;;) {
    const candidate = path.join(dir, 'main.typ');
    if (fs.existsSync(candidate)) return candidate;
    const parent = path.dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

// Run `action` with the document's main.typ as the active editor — Tinymist's
// commands act on whatever is active — then go back to the file being edited.
// Outside a document, or already on its main.typ, `action` runs as is.
async function onMainDocument(action) {
  const editor = vscode.window.activeTextEditor;
  const file = editor && editor.document.uri.scheme === 'file' ? editor.document.uri.fsPath : null;
  const main = file ? mainFor(file) : null;
  if (!main || main === file) return action();

  const doc = await vscode.workspace.openTextDocument(main);
  await vscode.window.showTextDocument(doc, { viewColumn: editor.viewColumn, preview: true });
  try {
    return await action();
  } finally {
    await vscode.window.showTextDocument(editor.document, {
      viewColumn: editor.viewColumn,
      selection: editor.selection,
    });
  }
}

async function previewDocument() {
  return onMainDocument(() => vscode.commands.executeCommand('typst-preview.preview'));
}

// tinymist.export returns once the PDF is written (the user-facing export
// command also waits on its own notification), so the editor switches back
// straight away and the result is reported here.
async function exportDocument() {
  let result;
  try {
    result = await onMainDocument(() => vscode.commands.executeCommand('tinymist.export', 'Pdf'));
  } catch (error) {
    vscode.window.showErrorMessage(`PDF export failed: ${error instanceof Error ? error.message : error}`);
    return;
  }
  if (!result || 'message' in result) {
    vscode.window.showErrorMessage(
      `PDF export failed${result && result.message ? `: ${result.message}` : ' — see the Problems panel.'}`);
    return;
  }
  const out = result.path || (result.items && result.items[0] && result.items[0].path);
  vscode.window.showInformationMessage(out ? `Exported ${vscode.workspace.asRelativePath(out)}` : 'PDF exported');
}

function activate(context) {
  context.subscriptions.push(
    vscode.commands.registerCommand('ajnotes.previewDocument', previewDocument),
    vscode.commands.registerCommand('ajnotes.exportDocument', exportDocument));
}

function deactivate() {}

module.exports = { activate, deactivate, mainFor };
