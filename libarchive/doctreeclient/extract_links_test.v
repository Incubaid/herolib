module doctreeclient

import os

fn test_extract_image_links() {
	// Test case 1: Basic case with one image link
	mut result := extract_image_links('Some text ![Alt Text](https://example.com/image1.png) more text',
		false)!
	assert result.len == 1
	assert result[0] == 'https://example.com/image1.png'

	// Test case 2: Multiple image links
	result = extract_image_links('![Img1](https://example.com/img1.jpg) Text ![Img2](https://example.com/img2.gif)',
		false)!
	assert result.len == 2
	assert result[0] == 'https://example.com/img1.jpg'
	assert result[1] == 'https://example.com/img2.gif'

	// Test case 3: No image links
	result = extract_image_links('Just some plain text without images.', false)!
	assert result.len == 0

	// Test case 4: Mixed content with other markdown
	result = extract_image_links('A link [Link](https://example.com) and an image ![Photo](https://example.com/photo.jpeg).',
		false)!
	assert result.len == 1
	assert result[0] == 'https://example.com/photo.jpeg'

	// Test case 5: Invalid image link (missing parenthesis)
	result = extract_image_links('Invalid ![Broken Link]https://example.com/broken.png',
		false)!
	assert result.len == 0

	// Test case 6: Empty string
	result = extract_image_links('', false)!
	assert result.len == 0

	// Test case 7: Image link at the beginning of the string
	result = extract_image_links('![Start](https://example.com/start.png) Some text.',
		false)!
	assert result.len == 1
	assert result[0] == 'https://example.com/start.png'

	// Test case 8: Image link at the end of the string
	result = extract_image_links('Some text ![End](https://example.com/end.png)', false)!
	assert result.len == 1
	assert result[0] == 'https://example.com/end.png'

	// Test case 9: Image link with spaces in URL (should not happen in valid markdown, but good to test robustness)
	result = extract_image_links('![Space](https://example.com/image with spaces.png)',
		false)!
	assert result.len == 1
	assert result[0] == 'https://example.com/image with spaces.png'

	// Test case 10: Image link with special characters in URL
	result = extract_image_links('![Special](https://example.com/path/to/image?id=1&name=test.png)',
		false)!
	assert result.len == 1
	assert result[0] == 'https://example.com/path/to/image?id=1&name=test.png'

	// Test case 11: Multiple image links without spaces in between
	result = extract_image_links('![A](https://a.com)![B](https://b.com)![C](https://c.com)',
		false)!
	assert result.len == 3
	assert result[0] == 'https://a.com'
	assert result[1] == 'https://b.com'
	assert result[2] == 'https://c.com'

	// Test case 12: Image link with empty alt text
	result = extract_image_links('![](https://example.com/noalt.png)', false)!
	assert result.len == 1
	assert result[0] == 'https://example.com/noalt.png'

	// Test case 13: Image link with empty URL (invalid markdown, but test behavior)
	result = extract_image_links('![Empty URL]()', false)!
	assert result.len == 1
	assert result[0] == '' // Expecting an empty string for the URL

	// Test case 14: Image link with only alt text and no URL part
	result = extract_image_links('![Only Alt Text]', false)!
	assert result.len == 0

	// Test case 15: Image link with only URL part and no alt text
	result = extract_image_links('()', false)!
	assert result.len == 0

	// --- Test cases for exclude_http = true ---

	// Test case 16: Exclude http links, only relative link
	result = extract_image_links('Some text ![Relative](image.png) ![Absolute](https://example.com/image.png)',
		true)!
	assert result.len == 1
	assert result[0] == 'image.png'

	// Test case 17: Exclude http links, multiple relative links
	result = extract_image_links('![Rel1](img1.jpg) ![Abs1](http://example.com/img.jpg) ![Rel2](/path/to/img2.gif)',
		true)!
	assert result.len == 2
	assert result[0] == 'img1.jpg'
	assert result[1] == '/path/to/img2.gif'

	// Test case 18: Exclude http links, all absolute links
	result = extract_image_links('![Abs1](https://example.com/img1.png) ![Abs2](http://example.com/img2.png)',
		true)!
	assert result.len == 0

	// Test case 19: Exclude http links, no links at all
	result = extract_image_links('Plain text.', true)!
	assert result.len == 0

	// Test case 20: Exclude http links, mixed absolute and relative, with other markdown
	result = extract_image_links('A link [Link](https://example.com) and an image ![Photo](https://example.com/photo.jpeg) and another ![Local](local.png).',
		true)!
	assert result.len == 1
	assert result[0] == 'local.png'

	// Test case 21: Exclude http links, empty string
	result = extract_image_links('', true)!
	assert result.len == 0

	// Test case 22: Exclude http links, image with empty URL (should still be included if not http)
	result = extract_image_links('![Empty URL]()', true)!
	assert result.len == 1
	assert result[0] == ''

	// Test case 23: Exclude http links, image with data URI (should not be excluded)
	result = extract_image_links('![Data URI](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=)',
		true)!
	assert result.len == 1
	assert result[0] == 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII='
}
