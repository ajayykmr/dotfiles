---
name: read-gdocs
description: Read a Google Doc through the Google Drive connector, including its images. The connector's read_file_content drops images (diagrams, screenshots, tables pasted as images) without a trace. Use this skill whenever reading a Google Doc (a docs.google.com/document link, or a Drive file of type Google Doc), or checking whether one has images.
allowed-tools: Bash(python3 -I ${CLAUDE_SKILL_DIR}/gdoc_images.py *)
---

# Read a Google Doc

`read_file_content` returns a doc's text and drops its images, leaving no marker where they were. The HTML export keeps every image inline, at its place in the text. This skill uses the export to find and read them. It covers Google Docs only, not spreadsheets or slides.

The script caches each doc's image count by doc ID, so a doc without images is not exported again until it changes. The cache is per machine, in `~/.cache/read-gdocs/docs.json`, and safe to delete.

A tool result too large to return inline is saved to a file, and the result gives the file's path. Steps 1 and 4 rely on this.

## Steps

`<doc-id>` is the ID in `docs.google.com/document/d/<doc-id>/`. Without a link, find the doc with `search_files`.

1. Read the text with `read_file_content`. If the result is saved to a file, read its `fileContent` in chunks until all of it is read.
2. Get the doc's `modifiedTime` with `get_file_metadata` and `excludeContentSnippets: true`. Steps 1 and 2 are independent: run them together.
3. Look up the cache:

   ```
   python3 -I ${CLAUDE_SKILL_DIR}/gdoc_images.py cached <doc-id> <modifiedTime>
   ```

   `images: 0` means the doc has no images, and the text from step 1 is the whole doc. Skip the remaining steps. For anything else, continue.
4. Export the doc with `download_file_content` and `exportMimeType: text/html`. The export is almost always saved to a file, even for a short doc. Continue with step 5.

   If it comes back inline as base64 instead, do not decode or search it. Treat the doc as having no images, and record that, with the title from step 1:

   ```
   python3 -I ${CLAUDE_SKILL_DIR}/gdoc_images.py record --title "<title>" <doc-id> <modifiedTime>
   ```

   Then skip the remaining steps: the text from step 1 is the whole doc. A small image in a small doc can be missed this way. The user points those out.
5. Extract the images from the saved export. This also records the result in the cache:

   ```
   python3 -I ${CLAUDE_SKILL_DIR}/gdoc_images.py extract --doc-id <doc-id> --modified-time <modifiedTime> <saved export> <scratchpad>/read-gdocs/<doc-id>
   ```

   `<scratchpad>` is the session's scratchpad folder, or a temporary folder if there is none. The script prints `title:`, then `images: N`, then one line per image: the saved file, pixel size, file size, and the text just before the image.
6. Read each saved image with the Read tool. Place it in the text right after its `after:` text. If step 1 saved the text to a file, search that file for it.

If you were only asked whether the doc has images, skip step 1, and stop once steps 3 to 5 give the count.
