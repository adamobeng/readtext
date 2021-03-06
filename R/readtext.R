## some globals
SUPPORTED_FILETYPE_MAPPING <-        c('csv', 'txt', 'json', 'zip', 'gz', 'tar', 'xml', 'tab', 'tsv', 'html', 'pdf', 'docx', 'doc')
names(SUPPORTED_FILETYPE_MAPPING) <- c('csv', 'txt', 'json', 'zip', 'gz', 'tar', 'xml', 'tab', 'tsv', 'html', 'pdf', 'docx', 'doc')
CHARACTER_CLASS_REPLACEMENTS = list(
                                    '\\p{Dash_Punctuation}' = '-',
                                    '\\p{Space_Separator}' = ' ',
                                    '\\p{Initial_Punctuation}' = "'",
                                    '\\p{Final_Punctuation}' = "'",
                                    '\\p{Private_Use}' = "",
                                    '\\p{Unassigned}' = ""
                                    )




#' read a text file(s)
#' 
#' Read texts and (if any) associated document-level meta-data from one or more source files. 
#' The text source files 
#' come from the textual component of the files, and the document-level
#' metadata ("docvars") come from either the file contents or filenames.
#' @param file the complete filename(s) to be read. This is designed to 
#'   automagically handle a number of common scenarios, so the value can be a
#    single filename, a vector of file names a remote URL, or a file "mask" using a 
#'   "glob"-type'  wildcard value.  Currently available filetypes are: 
#'   
#'   \strong{Single file formats:}
#'   
#'   \describe{
#'   \item{\code{txt}}{plain text files:
#'   So-called structured text files, which describe both texts and metadata:
#'   For all structured text filetypes, the column, field, or node 
#'   which contains the the text must be specified with the \code{text_field}
#'   parameter, and all other fields are treated as docvars.}
#'   \item{\code{json}}{data in some form of JavaScript 
#'   Object Notation, consisting of the texts and optionally additional docvars.
#'   The supported formats are:
#'   \itemize{
#'   \item a single JSON object per file
#'   \item line-delimited JSON, with one object per line
#'   \item line-delimited JSON, of the format produced from a Twitter stream.
#'   This type of file has special handling which simplifies the Twitter format
#'   into docvars.  The correct format for each JSON file is automatically detected.}}
#'   \item{\code{csv,tab,tsv}}{comma- or tab-separated values}
#'   \item{\code{xml}}{Basic flat XML documents are supported -- those of the 
#'   kind supported by the function xmlToDataFrame function of the \strong{XML} 
#'   package.}
#'   \item{\code{pdf}}{pdf formatted files, converted through \code{pdftotext}.  
#'   Requires that xpdf be installed, either through \code{brew install xpdf} (macOS) 
#'   or from \url{http://www.foolabs.com/xpdf/home.html} (Windows).}
#'   \item{\code{doc, docx}}{Microsoft Word formatted files, converted through 
#'   \code{antiword}.  
#'   Requires that \code{antiword} be installed, either through \code{brew install antiword} (macOS) 
#'   or from \url{http://www.winfield.demon.nl} (Windows).}
#'   
#'   \strong{Reading multiple files and file types:} 
#'   
#'   In addition, \code{file} can also not be a path 
#'   to a single local file, but also combinations of any of the above types, such as:
#'    \item{a wildcard value}{any valid 
#'   pathname with a wildcard ("glob") expression that can be expanded by the 
#'   operating system.  This may consist of multiple file types.} 
#'   \item{a URL to a remote}{which is downloaded then loaded} 
#'   \item{\code{zip,tar,tar.gz,tar.bz}}{archive file, which is unzipped. The 
#'   contained files must be either at the top level or in a single directory.
#'   Archives, remote URLs and glob patterns can resolve to any of the other 
#'   filetypes, so you could have, for example, a remote URL to a zip file which
#'   contained Twitter JSON files.}
#'   }
#' @param text_field a variable (column) name or column number indicating where 
#'   to find the texts that form the documents for the corpus.  This must be 
#'   specified for file types \code{.csv} and \code{.json}. For XML files
#'   an XPath expression can be specified. 
#' @param docvarsfrom  used to specify that docvars should be taken from the 
#'   filenames, when the \code{readtext} inputs are filenames and the elements 
#'   of the filenames are document variables, separated by a delimiter 
#'   (\code{dvsep}).  This allows easy assignment of docvars from filenames such
#'   as \code{1789-Washington.txt}, \code{1793-Washington}, etc. by \code{dvsep}
#'   or from meta-data embedded in the text file header (\code{headers}).
#'   If \code{docvarsfrom} is set to "filepaths", consider the full path to the
#'   file, not just the filename.
#' @param dvsep separator (a regular expression character string) used in 
#'  filenames to delimit docvar elements if  \code{docvarsfrom="filenames"} 
#'  or \code{docvarsfrom="filepaths"} is used
#' @param docvarnames character vector of variable names for \code{docvars}, if 
#'   \code{docvarsfrom} is specified.  If this argument is not used, default 
#'   docvar names will be used (\code{docvar1}, \code{docvar2}, ...).
#' @param encoding vector: either the encoding of all files, or one encoding
#'   for each files
#' @param ignore_missing_files if \code{FALSE}, then if the file
#'   argument doesn't resolve to an existing file, then an error will be thrown.
#'   Note that this can happen in a number of ways, including passing a path 
#'   to a file that does not exist, to an empty archive file, or to a glob 
#'   pattern that matches no files.
#' @param verbosity \itemize{
#'   \item 0: output errors only
#'   \item 1: output errors and warnings (default)
#'   \item 2: output a brief summary message
#'   \item 3: output detailed file-related messages
#' }
#' @param ... additional arguments passed through to low-level file reading 
#'   function, such as \code{\link{file}}, \code{\link{fread}}, etc.  Useful 
#'   for specifying an input encoding option, which is specified in the same was
#'   as it would be give to \code{\link{iconv}}.  See the Encoding section of 
#'   \link{file} for details.  
#' @return a data.frame consisting of a columns \code{doc_id} and \code{text} 
#'   that contain a document identifier and the texts respectively, with any 
#'   additional columns consisting of document-level variables either found 
#'   in the file containing the texts, or created through the 
#'   \code{readtext} call.
#' @export
#' @importFrom utils unzip type.convert
#' @importFrom httr GET write_disk
#' @examples 
#' \donttest{
#' ## get the data directory
#' DATA_DIR <- system.file("extdata/", package = "readtext")
#' 
#' ## read in some text data
#' # all UDHR files
#' (rt1 <- readtext(paste0(DATA_DIR, "txt/UDHR/*")))
#' 
#' # manifestos with docvars from filenames
#' (rt2 <- readtext(paste0(DATA_DIR, "txt/EU_manifestos/*.txt"),
#'                  docvarsfrom = "filenames", 
#'                  docvarnames = c("unit", "context", "year", "language", "party"),
#'                  encoding = "LATIN1"))
#'                  
#' # recurse through subdirectories
#' (rt3 <- readtext(paste0(DATA_DIR, "txt/movie_reviews/*"), 
#'                  docvarsfrom = "filepaths", docvarnames = "sentiment"))
#' 
#' ## read in csv data
#' (rt4 <- readtext(paste0(DATA_DIR, "csv/inaugCorpus.csv")))
#' 
#' ## read in tab-separated data
#' (rt5 <- readtext(paste0(DATA_DIR, "tsv/dailsample.tsv"), text_field = "speech"))
#' 
#' ## read in JSON data
#' (rt6 <- readtext(paste0(DATA_DIR, "json/inaugural_sample.json"), text_field = "texts"))
#' 
#' ## read in pdf data
#' # UNHDR
#' (rt7 <- readtext(paste0(DATA_DIR, "pdf/UDHR/*.pdf"), 
#'                  docvarsfrom = "filenames", 
#'                  docvarnames = c("document", "language")))
#' Encoding(rt7$text)
#'
#' ## read in Word data (.doc)
#' (rt8 <- readtext(paste0(DATA_DIR, "word/*.doc")))
#' Encoding(rt8$text)
#'
#' ## read in Word data (.docx)
#' (rt9 <- readtext(paste0(DATA_DIR, "word/*.docx")))
#' Encoding(rt9$text)
#'
#' ## use elements of path and filename as docvars
#' (rt10 <- readtext(paste0(DATA_DIR, "pdf/UDHR/*.pdf"), 
#'                   docvarsfrom = "filepaths", dvsep = "[/_.]"))
#' }
readtext <- function(file, ignore_missing_files = FALSE, text_field = NULL, 
                    docvarsfrom = c("metadata", "filenames", "filepaths"), dvsep="_", 
                    docvarnames = NULL, encoding = NULL, 
                    verbosity = getOption("readtext_verbosity"),
                    ...) {
    
    # trap "textfield", issue a warning, and call with text_field
    thecall <- as.list(match.call())
    thecall <- thecall[2:length(thecall)]
    if ("textfield" %in% names(thecall)) {
        warning("textfield is deprecated; use text_field instead")
        names(thecall)[which(names(thecall)=="textfield")] <- "text_field"
        return(do.call(readtext, thecall))
    }
    
    # in case the function was called without attaching the package, 
    # in which case the option is never set
    if (is.null(verbosity)) { 
        verbosity <- 1
    }
    if (!verbosity %in% 0:3) 
        stop("verbosity must be one of 0, 1, 2, 3")
    orig_verbosity <- getOption("readtext_verbosity")
    options('readtext_verbosity' = verbosity)
    # some error checks
    if (!is.character(file))
        stop("file must be a character (specifying file location(s))")
    
    docvarsfrom <- match.arg(docvarsfrom)
    # # just use the first, if both are specified?
    # if (is.missing(docvarsfrom))
    #     
    # if (!all(docvarsfrom %in% c( c("metadata", "filenames"))))
    #     stop("illegal docvarsfrom value")
     
    if (verbosity >= 2) {
        msg <- paste0("Reading texts from ", file)
        message(msg, appendLF = FALSE)
    }
    
    if (is.null(text_field)) text_field <- 1
    files <- listMatchingFiles(file, ignoreMissing = ignore_missing_files)

    if (is.null(encoding)) {
        encoding <- getOption("encoding")
    }
    if (length(encoding) > 1) {
        if (length(encoding) != length(files)) {
            stop('encoding parameter must be length 1, or as long as the number of files')
        }
        sources <- mapply(function(x, e) getSource(f = x, text_field = text_field, encoding = e, ...),
                         files, encoding,
                         SIMPLIFY = FALSE)
    } else {
        sources <- lapply(files, function(x) getSource(x, text_field = text_field, encoding = encoding, ...))
    }

    
    # combine all of the data.frames returned
    result <- data.frame(doc_id = "", 
                         data.table::rbindlist(sources, use.names = TRUE, fill = TRUE),
                         stringsAsFactors = FALSE)

    # this is in case some smart-alec (like AO) globs different directories 
    # for identical filenames
    uniqueparts <- basename_unique(files, pathonly = TRUE)
    row.names(result) <- if (!identical(uniqueparts, "")) {
         paste(uniqueparts, as.character(as.character(unlist(sapply(sources, row.names)))), sep = "/")
    } else {
         as.character(unlist(sapply(sources, row.names)))
    }

    if ("filenames" %in% docvarsfrom) {
        filenameDocvars <- getdocvarsFromFilenames(files, dvsep = dvsep, 
                                                   docvarnames = docvarnames, include_path=FALSE)
        result <- cbind(result, imputeDocvarsTypes(filenameDocvars))
    } else if ("filepaths" %in% docvarsfrom) {
        filenameDocvars <- getdocvarsFromFilenames(files, dvsep = dvsep, 
                                                   docvarnames = docvarnames, include_path=TRUE)
        result <- cbind(result, imputeDocvarsTypes(filenameDocvars))
    }
    
    # change rownames to doc_id 
    result$doc_id <- rownames(result)
    rownames(result) <- NULL
    
    if (verbosity >= 2) {
        pad <- ""
        if (verbosity == 2) pad <- " ... "
        if (verbosity == 2 & nchar(msg) >70) pad <- paste0("\n", pad)
        message(pad, "read ", nrow(result), " document", 
                ifelse(nrow(result) == 1, "", "s."))
    }
    
    # reset verbosity level to that before overridden by call
    options('readtext_verbosity' = orig_verbosity)

    class(result) <- c("readtext", class(result))
    result
}

## read each file as appropriate, calling the get_* functions for recognized
## file types
getSource <- function(f, text_field, replace_special_characters = FALSE, ...) {

    fileType <- tolower(file_ext(f))
    if (fileType %in% SUPPORTED_FILETYPE_MAPPING) {
        if (dir.exists(f)) {
            call <- deparse(sys.call(1))
            call <- sub(f, paste0(sub('/$', '', f), '/*'), call, fixed = TRUE)
            stop("File '", f, "' does not exist, but a directory of this name does exist. ",
                 "To read all files in a directory, you must pass a glob expression like ",
                 call
            )
        }
    } else {
        if (getOption("readtext_verbosity") >= 1) warning(paste('Unsupported extension "', fileType, '" of file', f, 'treating as plain text'))
        fileType <- 'txt'
    }
    
    newSource <- switch(fileType, 
               txt = get_txt(f, ...),
               csv = get_csv(f, text_field, sep=',', ...),
               tsv = get_csv(f, text_field, sep='\t', ...),
               tab = get_csv(f, text_field, sep='\t', ...),
               json = get_json(f, text_field, ...),
               xml = get_xml(f, text_field, ...),
               html = get_html(f, text_field=text_field, ...),
               pdf = get_pdf(f, ...),
               docx = get_docx(f, ...),
               doc = get_doc(f, ...)
        )

    # assign filename (variants) unique text names
    if ((len <- nrow(newSource)) > 1) {
        row.names(newSource) <- paste(basename(f), seq_len(len), sep = ".")
    } else {
        row.names(newSource) <- basename(f)
    }

    if (replace_special_characters) {
        newSource$text <- sapply(newSource$text, make_character_class_replacements)
    }

    # replace unicode characters classes
    return(newSource)
}

make_character_class_replacements <- function (char, mapping = CHARACTER_CLASS_REPLACEMENTS)  {
    for (i in names(mapping)) {
        char <- stringi::stri_replace_all(char, mapping[i], regex = i)
    }
    char
}
