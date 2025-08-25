# Custom Ghost Theme

A custom Ghost theme inspired by the design of portfolio.tawfiqulbari.work. This theme features a modern dark design with clean typography, smooth animations, and responsive layout.

## Features

- Modern dark theme design
- Fully responsive layout
- Clean typography and spacing
- Smooth animations and transitions
- Support for Ghost members
- SEO optimized
- Fast loading with lazy image loading

## Installation

1. Zip the entire `custom-ghost-theme` directory
2. Log in to your Ghost admin panel at `https://blog.tawfiqulbari.work/ghost`
3. Go to Settings → Design
4. Upload the zip file under "Upload a theme"
5. Activate the theme

## Customization

The theme supports several custom settings through Ghost's built-in custom fields:

### Hero Section
- Enable/disable hero section in Ghost settings
- Set hero title, description, and button text/links

### Colors and Styles
- Primary color: #007bff (blue accent)
- Background: #0a0a0a (dark background)
- Text: #ffffff (white text)
- Cards: #1a1a1a with subtle borders

### Typography
- Uses system fonts for fast loading
- Responsive font sizes
- Clean heading hierarchy

## File Structure

```
custom-ghost-theme/
├── assets/
│   ├── css/
│   │   └── screen.css
│   └── js/
│       └── main.js
├── partials/
│   ├── navigation.hbs
│   └── pagination.hbs
├── default.hbs
├── index.hbs
├── post.hbs
├── page.hbs
├── error.hbs
├── author.hbs
├── tag.hbs
├── package.json
└── README.md
```

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)
- Mobile browsers

## License

MIT License - feel free to modify and use as needed.