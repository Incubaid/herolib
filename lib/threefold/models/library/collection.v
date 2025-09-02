module library

// Collection represents a collection of library items
@[heap]
pub struct Collection {
pub mut:
	id          u32      // Unique collection ID
	title       string   // Title of the collection
	description ?string  // Optional description of the collection
	images      []u32    // List of image item IDs belonging to this collection
	pdfs        []u32    // List of PDF item IDs belonging to this collection
	markdowns   []u32    // List of Markdown item IDs belonging to this collection
	books       []u32    // List of Book item IDs belonging to this collection
	slides      []u32    // List of Slides item IDs belonging to this collection
	created_at  u64      // Creation timestamp
	updated_at  u64      // Last update timestamp
}

// new creates a new Collection with default values
pub fn Collection.new() Collection {
	return Collection{
		id: 0
		title: ''
		description: none
		images: []
		pdfs: []
		markdowns: []
		books: []
		slides: []
		created_at: 0
		updated_at: 0
	}
}

// title sets the title of the collection (builder pattern)
pub fn (mut c Collection) title(title string) Collection {
	c.title = title
	return c
}

// description sets the description of the collection (builder pattern)
pub fn (mut c Collection) description(description string) Collection {
	c.description = description
	return c
}

// add_image adds an image ID to the collection (builder pattern)
pub fn (mut c Collection) add_image(image_id u32) Collection {
	c.images << image_id
	return c
}

// add_pdf adds a PDF ID to the collection (builder pattern)
pub fn (mut c Collection) add_pdf(pdf_id u32) Collection {
	c.pdfs << pdf_id
	return c
}

// add_markdown adds a markdown ID to the collection (builder pattern)
pub fn (mut c Collection) add_markdown(markdown_id u32) Collection {
	c.markdowns << markdown_id
	return c
}

// add_book adds a book ID to the collection (builder pattern)
pub fn (mut c Collection) add_book(book_id u32) Collection {
	c.books << book_id
	return c
}

// add_slides adds a slides ID to the collection (builder pattern)
pub fn (mut c Collection) add_slides(slides_id u32) Collection {
	c.slides << slides_id
	return c
}

// total_items returns the total number of items in the collection
pub fn (c Collection) total_items() u32 {
	return u32(c.images.len + c.pdfs.len + c.markdowns.len + c.books.len + c.slides.len)
}

// has_images checks if the collection has any images
pub fn (c Collection) has_images() bool {
	return c.images.len > 0
}

// has_pdfs checks if the collection has any PDFs
pub fn (c Collection) has_pdfs() bool {
	return c.pdfs.len > 0
}

// has_markdowns checks if the collection has any markdown documents
pub fn (c Collection) has_markdowns() bool {
	return c.markdowns.len > 0
}

// has_books checks if the collection has any books
pub fn (c Collection) has_books() bool {
	return c.books.len > 0
}

// has_slides checks if the collection has any slideshows
pub fn (c Collection) has_slides() bool {
	return c.slides.len > 0
}

// is_empty checks if the collection is empty
pub fn (c Collection) is_empty() bool {
	return c.total_items() == 0
}

// remove_image removes an image ID from the collection
pub fn (mut c Collection) remove_image(image_id u32) {
	c.images = c.images.filter(it != image_id)
}

// remove_pdf removes a PDF ID from the collection
pub fn (mut c Collection) remove_pdf(pdf_id u32) {
	c.pdfs = c.pdfs.filter(it != pdf_id)
}

// remove_markdown removes a markdown ID from the collection
pub fn (mut c Collection) remove_markdown(markdown_id u32) {
	c.markdowns = c.markdowns.filter(it != markdown_id)
}

// remove_book removes a book ID from the collection
pub fn (mut c Collection) remove_book(book_id u32) {
	c.books = c.books.filter(it != book_id)
}

// remove_slides removes a slides ID from the collection
pub fn (mut c Collection) remove_slides(slides_id u32) {
	c.slides = c.slides.filter(it != slides_id)
}

// contains_image checks if the collection contains a specific image
pub fn (c Collection) contains_image(image_id u32) bool {
	return image_id in c.images
}

// contains_pdf checks if the collection contains a specific PDF
pub fn (c Collection) contains_pdf(pdf_id u32) bool {
	return pdf_id in c.pdfs
}

// contains_markdown checks if the collection contains a specific markdown
pub fn (c Collection) contains_markdown(markdown_id u32) bool {
	return markdown_id in c.markdowns
}

// contains_book checks if the collection contains a specific book
pub fn (c Collection) contains_book(book_id u32) bool {
	return book_id in c.books
}

// contains_slides checks if the collection contains a specific slideshow
pub fn (c Collection) contains_slides(slides_id u32) bool {
	return slides_id in c.slides
}

// get_description_string returns the description as a string (empty if none)
pub fn (c Collection) get_description_string() string {
	return c.description or { '' }
}