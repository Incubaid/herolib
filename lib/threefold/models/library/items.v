module library

// Image represents an Image library item
@[heap]
pub struct Image {
pub mut:
	id          u32     // Unique image ID
	title       string  // Title of the image
	description ?string // Optional description of the image
	url         string  // URL of the image
	width       u32     // Width of the image in pixels
	height      u32     // Height of the image in pixels
	created_at  u64     // Creation timestamp
	updated_at  u64     // Last update timestamp
}

// new creates a new Image with default values
pub fn Image.new() Image {
	return Image{
		id:          0
		title:       ''
		description: none
		url:         ''
		width:       0
		height:      0
		created_at:  0
		updated_at:  0
	}
}

// title sets the title of the image (builder pattern)
pub fn (mut i Image) title(title string) Image {
	i.title = title
	return i
}

// description sets the description of the image (builder pattern)
pub fn (mut i Image) description(description string) Image {
	i.description = description
	return i
}

// url sets the URL of the image (builder pattern)
pub fn (mut i Image) url(url string) Image {
	i.url = url
	return i
}

// width sets the width of the image (builder pattern)
pub fn (mut i Image) width(width u32) Image {
	i.width = width
	return i
}

// height sets the height of the image (builder pattern)
pub fn (mut i Image) height(height u32) Image {
	i.height = height
	return i
}

// aspect_ratio calculates the aspect ratio of the image
pub fn (i Image) aspect_ratio() f64 {
	if i.height == 0 {
		return 0.0
	}
	return f64(i.width) / f64(i.height)
}

// is_landscape checks if the image is in landscape orientation
pub fn (i Image) is_landscape() bool {
	return i.width > i.height
}

// is_portrait checks if the image is in portrait orientation
pub fn (i Image) is_portrait() bool {
	return i.height > i.width
}

// is_square checks if the image is square
pub fn (i Image) is_square() bool {
	return i.width == i.height
}

// Pdf represents a PDF document library item
@[heap]
pub struct Pdf {
pub mut:
	id          u32     // Unique PDF ID
	title       string  // Title of the PDF
	description ?string // Optional description of the PDF
	url         string  // URL of the PDF file
	page_count  u32     // Number of pages in the PDF
	created_at  u64     // Creation timestamp
	updated_at  u64     // Last update timestamp
}

// new creates a new Pdf with default values
pub fn Pdf.new() Pdf {
	return Pdf{
		id:          0
		title:       ''
		description: none
		url:         ''
		page_count:  0
		created_at:  0
		updated_at:  0
	}
}

// title sets the title of the PDF (builder pattern)
pub fn (mut p Pdf) title(title string) Pdf {
	p.title = title
	return p
}

// description sets the description of the PDF (builder pattern)
pub fn (mut p Pdf) description(description string) Pdf {
	p.description = description
	return p
}

// url sets the URL of the PDF (builder pattern)
pub fn (mut p Pdf) url(url string) Pdf {
	p.url = url
	return p
}

// page_count sets the page count of the PDF (builder pattern)
pub fn (mut p Pdf) page_count(page_count u32) Pdf {
	p.page_count = page_count
	return p
}

// is_empty checks if the PDF has no pages
pub fn (p Pdf) is_empty() bool {
	return p.page_count == 0
}

// Markdown represents a Markdown document library item
@[heap]
pub struct Markdown {
pub mut:
	id          u32     // Unique markdown ID
	title       string  // Title of the document
	description ?string // Optional description of the document
	content     string  // The markdown content
	created_at  u64     // Creation timestamp
	updated_at  u64     // Last update timestamp
}

// new creates a new Markdown document with default values
pub fn Markdown.new() Markdown {
	return Markdown{
		id:          0
		title:       ''
		description: none
		content:     ''
		created_at:  0
		updated_at:  0
	}
}

// title sets the title of the document (builder pattern)
pub fn (mut m Markdown) title(title string) Markdown {
	m.title = title
	return m
}

// description sets the description of the document (builder pattern)
pub fn (mut m Markdown) description(description string) Markdown {
	m.description = description
	return m
}

// content sets the content of the document (builder pattern)
pub fn (mut m Markdown) content(content string) Markdown {
	m.content = content
	return m
}

// word_count estimates the word count of the markdown content
pub fn (m Markdown) word_count() u32 {
	words := m.content.split(' ').filter(it.trim_space().len > 0)
	return u32(words.len)
}

// is_empty checks if the markdown content is empty
pub fn (m Markdown) is_empty() bool {
	return m.content.trim_space().len == 0
}

// TocEntry represents a table of contents entry for a book
pub struct TocEntry {
pub mut:
	title       string     // Title of the chapter/section
	page        u32        // Page number (index in the pages array)
	subsections []TocEntry // Optional subsections
}

// new creates a new TocEntry with default values
pub fn TocEntry.new() TocEntry {
	return TocEntry{
		title:       ''
		page:        0
		subsections: []
	}
}

// title sets the title of the TOC entry (builder pattern)
pub fn (mut te TocEntry) title(title string) TocEntry {
	te.title = title
	return te
}

// page sets the page number of the TOC entry (builder pattern)
pub fn (mut te TocEntry) page(page u32) TocEntry {
	te.page = page
	return te
}

// add_subsection adds a subsection to the TOC entry (builder pattern)
pub fn (mut te TocEntry) add_subsection(subsection TocEntry) TocEntry {
	te.subsections << subsection
	return te
}

// has_subsections checks if the TOC entry has subsections
pub fn (te TocEntry) has_subsections() bool {
	return te.subsections.len > 0
}

// Book represents a Book library item (collection of markdown pages with TOC)
@[heap]
pub struct Book {
pub mut:
	id                u32        // Unique book ID
	title             string     // Title of the book
	description       ?string    // Optional description of the book
	table_of_contents []TocEntry // Table of contents
	pages             []string   // Pages content (markdown strings)
	created_at        u64        // Creation timestamp
	updated_at        u64        // Last update timestamp
}

// new creates a new Book with default values
pub fn Book.new() Book {
	return Book{
		id:                0
		title:             ''
		description:       none
		table_of_contents: []
		pages:             []
		created_at:        0
		updated_at:        0
	}
}

// title sets the title of the book (builder pattern)
pub fn (mut b Book) title(title string) Book {
	b.title = title
	return b
}

// description sets the description of the book (builder pattern)
pub fn (mut b Book) description(description string) Book {
	b.description = description
	return b
}

// add_page adds a page to the book (builder pattern)
pub fn (mut b Book) add_page(content string) Book {
	b.pages << content
	return b
}

// add_toc_entry adds a TOC entry to the book (builder pattern)
pub fn (mut b Book) add_toc_entry(entry TocEntry) Book {
	b.table_of_contents << entry
	return b
}

// table_of_contents sets the table of contents (builder pattern)
pub fn (mut b Book) table_of_contents(toc []TocEntry) Book {
	b.table_of_contents = toc
	return b
}

// pages sets all pages at once (builder pattern)
pub fn (mut b Book) pages(pages []string) Book {
	b.pages = pages
	return b
}

// page_count returns the number of pages in the book
pub fn (b Book) page_count() u32 {
	return u32(b.pages.len)
}

// get_page gets a page by index (0-based)
pub fn (b Book) get_page(index u32) ?string {
	if index < u32(b.pages.len) {
		return b.pages[index]
	}
	return none
}

// has_toc checks if the book has a table of contents
pub fn (b Book) has_toc() bool {
	return b.table_of_contents.len > 0
}

// is_empty checks if the book has no pages
pub fn (b Book) is_empty() bool {
	return b.pages.len == 0
}

// Slide represents a single slide in a slideshow
pub struct Slide {
pub mut:
	image_url   string  // URL of the slide image
	title       ?string // Optional slide title
	description ?string // Optional slide description
}

// new creates a new Slide
pub fn Slide.new() Slide {
	return Slide{
		image_url:   ''
		title:       none
		description: none
	}
}

// url sets the image URL (builder pattern)
pub fn (mut s Slide) url(url string) Slide {
	s.image_url = url
	return s
}

// title sets the slide title (builder pattern)
pub fn (mut s Slide) title(title string) Slide {
	s.title = title
	return s
}

// description sets the slide description (builder pattern)
pub fn (mut s Slide) description(description string) Slide {
	s.description = description
	return s
}

// has_title checks if the slide has a title
pub fn (s Slide) has_title() bool {
	return s.title != none
}

// has_description checks if the slide has a description
pub fn (s Slide) has_description() bool {
	return s.description != none
}

// Slideshow represents a Slideshow library item (collection of images for slideshow)
@[heap]
pub struct Slideshow {
pub mut:
	id          u32     // Unique slideshow ID
	title       string  // Title of the slideshow
	description ?string // Optional description of the slideshow
	slides      []Slide // List of slides
	created_at  u64     // Creation timestamp
	updated_at  u64     // Last update timestamp
}

// new creates a new Slideshow with default values
pub fn Slideshow.new() Slideshow {
	return Slideshow{
		id:          0
		title:       ''
		description: none
		slides:      []
		created_at:  0
		updated_at:  0
	}
}

// title sets the title of the slideshow (builder pattern)
pub fn (mut s Slideshow) title(title string) Slideshow {
	s.title = title
	return s
}

// description sets the description of the slideshow (builder pattern)
pub fn (mut s Slideshow) description(description string) Slideshow {
	s.description = description
	return s
}

// add_slide adds a slide to the slideshow (builder pattern)
pub fn (mut s Slideshow) add_slide(slide Slide) Slideshow {
	s.slides << slide
	return s
}

// slide_count returns the number of slides
pub fn (s Slideshow) slide_count() u32 {
	return u32(s.slides.len)
}

// get_slide gets a slide by index (0-based)
pub fn (s Slideshow) get_slide(index u32) ?Slide {
	if index < u32(s.slides.len) {
		return s.slides[index]
	}
	return none
}

// is_empty checks if the slideshow has no slides
pub fn (s Slideshow) is_empty() bool {
	return s.slides.len == 0
}

// remove_slide removes a slide by index
pub fn (mut s Slideshow) remove_slide(index u32) {
	if index < u32(s.slides.len) {
		s.slides.delete(int(index))
	}
}
