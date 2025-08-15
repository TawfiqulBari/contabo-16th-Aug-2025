# 📸 Adding Your Professional Photo

## 🎯 Current Status
✅ Portfolio structure updated to include your professional photo
✅ Placeholder image is currently showing
⏳ **Next Step**: Replace with your actual photo

---

## 📁 Quick Method: Direct File Copy

### **Option 1: Upload via SCP/SFTP**
```bash
# From your local machine, upload the image:
scp your-photo.jpg user@server:/opt/info-web/portfolio/images/tawfiqul-bari-professional.jpg

# Then rebuild the container:
cd /opt/info-web/portfolio
docker compose -f docker-compose.traefik.yml up --build -d
```

### **Option 2: Using the Upload Script**
```bash
# Run the interactive upload script:
./upload-photo.sh

# Follow the prompts to upload your photo
```

### **Option 3: Manual Copy (if you have the file on the server)**
```bash
# Copy your photo to the images directory:
cp /path/to/your/photo.jpg /opt/info-web/portfolio/images/tawfiqul-bari-professional.jpg

# Make sure it has the right permissions:
chmod 644 /opt/info-web/portfolio/images/tawfiqul-bari-professional.jpg

# Rebuild the portfolio:
cd /opt/info-web/portfolio
docker compose -f docker-compose.traefik.yml up --build -d
```

---

## 🎨 Photo Specifications

### **Recommended Settings**
- **Format**: JPG or PNG
- **Dimensions**: 400x400 pixels (square) for best results
- **File Size**: Under 200KB for fast loading
- **Quality**: High resolution, professional business photo
- **Background**: Clean, professional background (like in your current photo)

### **Your Current Photo Details**
From the image you shared:
- ✅ Professional business attire
- ✅ Clean background
- ✅ Good lighting and composition
- ✅ Professional setting
- 📝 **Perfect for executive-level portfolio!**

---

## 🔄 After Adding Your Photo

### **Test the Update**
```bash
# Check if the photo is accessible:
curl -I https://portfolio.tawfiqulbari.work/images/tawfiqul-bari-professional.jpg

# View your updated portfolio:
curl -I https://portfolio.tawfiqulbari.work/
```

### **Where Your Photo Will Appear**
1. **🏠 Hero Section**: Large circular professional photo (400x400px)
2. **👨‍💼 About Section**: Smaller rectangular photo (200x200px)
3. **📱 Mobile Version**: Optimized for all screen sizes

---

## 🚀 Immediate Action Required

### **Step 1: Get Your Photo Ready**
- Save the professional photo from your image
- Crop to square format (1:1 aspect ratio) if needed
- Optimize file size (under 200KB)

### **Step 2: Upload to Server**
Choose one of the methods above to upload your photo as:
`/opt/info-web/portfolio/images/tawfiqul-bari-professional.jpg`

### **Step 3: Rebuild Portfolio**
```bash
cd /opt/info-web/portfolio
docker compose -f docker-compose.traefik.yml up --build -d
```

### **Step 4: Verify**
Visit: **https://portfolio.tawfiqulbari.work**

---

## 🎯 Expected Result

After uploading your photo, visitors will see:
- **Professional circular photo** in the hero section
- **Your actual headshot** instead of the placeholder
- **Consistent branding** across all sections
- **Mobile-optimized** display on all devices

---

## 💡 Pro Tips

### **Photo Enhancement**
- Use the same professional photo from your shared image
- Consider having a few variations (different angles/crops)
- Ensure the photo represents your current professional appearance

### **File Naming**
- Main photo: `tawfiqul-bari-professional.jpg`
- Alternative: `tawfiqul-bari-hero.jpg` (optional larger version)

### **Testing**
After upload, test on:
- Desktop browser
- Mobile device
- Print version
- Social media sharing (LinkedIn, etc.)

---

**🎊 Once you add your professional photo, your portfolio will be 100% complete with your personal branding!**

**📸 Your professional image will perfectly complement the executive-level design and content.**
