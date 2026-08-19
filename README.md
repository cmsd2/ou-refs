# ou-refs

Citing Open University module materials from LaTeX, in a Harvard-flavoured
biblatex style, so that a citation reads:

> ... the test statistic is boxed in **[M140 Unit 10, Section 4.1, p. 51]**

and the reference list follows Cite Them Right (OU Harvard):

> The Open University (2021) 'Unit 10: Experiments', *M140 Introducing
> statistics*. Milton Keynes: The Open University.

## Install

```sh
make link      # symlink into TEXMFHOME; repo edits take effect immediately
make check     # confirm kpsewhich resolves both files
make test      # build example.tex from a dir holding neither file
```

`make install` copies instead of symlinking — use that on a machine where you
don't keep the repo checked out. `make uninstall` removes both.

The Makefile resolves `TEXMFHOME` with `kpsewhich -var-value=TEXMFHOME`, so the
same commands work on macOS (`~/Library/texmf`) and Linux (`~/texmf`). No
`texhash` is needed: `TEXMFHOME` is not in `TEXMFDBS`, so it is scanned live.

### On CoCalc

```sh
git clone https://github.com/cmsd2/ou-refs.git ~/ou-refs
cd ~/ou-refs && make link && make check
```

No sudo required — everything lands under `$HOME`.

## Use

```latex
\usepackage[style=british]{csquotes}                       % single quotes
\usepackage[backend=biber, style=authoryear, dashed=false]{biblatex}
\addbibresource{ou-refs.bib}      % central, from TEXMFHOME (OU units)
\addbibresource{local-refs.bib}   % alongside the .tex      (Mendeley export)
\usepackage{ou-refs}              % MUST come after biblatex
```

| Command | Output |
|---|---|
| `\oucite{m140:u10}{Section 4.1}{51}` | [M140 Unit 10, Section 4.1, p. 51] |
| `\oucite{m140:u10}{Section 4.1}{51--53}` | [M140 Unit 10, Section 4.1, pp. 51–53] |
| `\oucites{m140:u10}{Section 2.3}` | [M140 Unit 10, Section 2.3] |
| `\sqcite{m140:hb}` | [M140 Handbook] |
| `\sqcite{m140:u10,m140:u12}` | [M140 Unit 10; M140 Unit 12] |
| `\parencite{gosset1908}` | (Student 1908) |

p. vs pp. is chosen by biblatex's own `\mkpageprefix`, so ranges, comma lists
and roman numerals all work.

## Two bibliographies

`biblatex` accepts any number of `\addbibresource` lines and merges them into
one reference list, so the split costs nothing:

- **`ou-refs.bib`** (this repo, installed to TEXMFHOME) — OU module units.
  Hand-maintained, shared across every TMA, cited by shorthand.
- **`local-refs.bib`** (next to each document) — whatever Mendeley exports.
  Cited normally, author–date.

Keep OU units *out* of Mendeley. The `[M140 Unit 10]` label comes from
biblatex's `shorthand` field, and Mendeley's BibTeX export has no field that
maps to it — the labels would not survive a round trip.

If you would rather have one file per document, `make install` is optional:
just copy `ou-refs.bib` next to the `.tex` and drop the TEXMFHOME half. You
then maintain N copies, which is the thing this repo exists to avoid.

## Adding a module

One `@xdata` block for the shared fields, then one `@incollection` per unit:

```bibtex
@xdata{ou:mst224,
  author    = {{The Open University}},
  date      = {2021},
  booktitle = {MST224 Mathematical methods},
  location  = {Milton Keynes},
  publisher = {The Open University},
  keywords  = {oumodule},          % this is what suppresses "In:"
}

@incollection{mst224:u1, xdata = {ou:mst224},
  title = {Unit 1: ...}, shorthand = {MST224 Unit 1}}
```

`@xdata` rather than `crossref`: inheritance from `@book` to `@incollection`
is not well defined and maps `title` wrongly, whereas `@xdata` copies
field-for-field. The double braces on `{{The Open University}}` are required,
or biber reads "University" as a surname.

Dates are the edition years of the PDFs under `../modules`. Cite Them Right
wants the presentation year printed on your own copy — check the imprint page
before submitting.

## Notes

- `\printbiblist{shorthand}` emits a list of abbreviations, which Harvard
  guides expect when you cite by abbreviation.
- `\textcite` on an OU entry reads oddly ("The Open University (M140 Unit
  12)") because the shorthand occupies the year slot. Use `\sqcite`.
- `ou-tma.sty` in TEXMFHOME is a separate CTAN package, generated from
  `ou-tma.dtx`. Don't edit it; anything added there is lost on rebuild.
