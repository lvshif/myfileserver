# Troubleshooting Guide - Buttons Not Working

## Issue: Copy, Move, Delete, New Folder, New File buttons not working

### Quick Fix Steps

#### 1. Clear Browser Cache (Most Common Issue)
```
Press: Ctrl + Shift + R (Windows/Linux)
Or: Cmd + Shift + R (Mac)
Or: Ctrl + F5
```

This forces the browser to reload all files without using cache.

#### 2. Check Browser Console for Errors
1. Open browser (Chrome/Firefox/Edge)
2. Press F12 to open Developer Tools
3. Click on "Console" tab
4. Refresh the page
5. Look for any red error messages

Common errors to look for:
- `Uncaught ReferenceError: showCreateDirModal is not defined`
- `Uncaught SyntaxError`
- `Failed to load resource`

#### 3. Verify Server is Running
```bash
ps aux | grep fileserver.py
```

Should show:
```
root  XXXXX  python3 /jason/script/fileserver/fileserver.py 80
```

#### 4. Restart Server
```bash
# Stop server
sudo pkill -f fileserver.py

# Start server
cd /jason/script/fileserver
sudo python3 fileserver.py 80 &

# Verify it's running
ps aux | grep fileserver.py
```

#### 5. Test with curl
```bash
# Test if server responds
curl -I http://localhost/

# Should return:
HTTP/1.0 200 OK
```

#### 6. Check if JavaScript is loaded
```bash
curl -s http://localhost/ | grep "function showCreateDirModal"
```

Should return a line containing the function definition.

#### 7. Try Different Browser
- Chrome
- Firefox  
- Edge
- Safari

Sometimes one browser caches more aggressively than others.

#### 8. Check Browser JavaScript Settings
Make sure JavaScript is enabled:
- Chrome: Settings → Privacy and security → Site Settings → JavaScript → Allowed
- Firefox: about:config → javascript.enabled → true

### Advanced Debugging

#### Check Network Tab
1. Open Developer Tools (F12)
2. Go to "Network" tab
3. Refresh page
4. Look for the main page request
5. Click on it
6. Check "Response" tab
7. Search for "showCreateDirModal" - it should be there

#### Test JavaScript in Console
Open browser console (F12 → Console) and type:
```javascript
typeof showCreateDirModal
```

Should return: `"function"`

If it returns `"undefined"`, the JavaScript didn't load properly.

#### Manual Function Test
In browser console, try:
```javascript
showCreateDirModal()
```

This should open the "New Folder" modal.

### Common Issues and Solutions

#### Issue 1: "function is not defined"
**Cause**: JavaScript didn't load or has syntax error
**Solution**: 
1. Clear cache (Ctrl + Shift + R)
2. Check server logs
3. Restart server

#### Issue 2: Buttons click but nothing happens
**Cause**: Modal CSS not loading or JavaScript error
**Solution**:
1. Check browser console for errors
2. Verify CSS is loaded
3. Clear cache

#### Issue 3: Some buttons work, others don't
**Cause**: Partial JavaScript load or specific function error
**Solution**:
1. Check which functions work
2. Look for errors in console
3. Restart server

#### Issue 4: Works in one browser, not another
**Cause**: Browser-specific caching or compatibility
**Solution**:
1. Clear cache in problematic browser
2. Try incognito/private mode
3. Check browser console

### Server-Side Checks

#### Verify File Integrity
```bash
# Check file size
ls -lh /jason/script/fileserver/fileserver.py

# Should be around 66-70KB
```

#### Check for Syntax Errors
```bash
python3 -m py_compile /jason/script/fileserver/fileserver.py
```

No output = no syntax errors

#### View Server Logs
If running with nohup:
```bash
tail -f /jason/script/fileserver/fileserver.log
```

If running with systemd:
```bash
sudo journalctl -u fileserver -f
```

### Nuclear Option: Complete Reset

If nothing works:

```bash
# 1. Stop server
sudo pkill -f fileserver.py

# 2. Backup current file
cp /jason/script/fileserver/fileserver.py /jason/script/fileserver/fileserver.py.backup

# 3. Restart server
cd /jason/script/fileserver
sudo python3 fileserver.py 80 &

# 4. Clear ALL browser data
# In browser: Settings → Privacy → Clear browsing data → All time → Everything

# 5. Access in incognito mode
# Chrome: Ctrl + Shift + N
# Firefox: Ctrl + Shift + P
```

### Test Checklist

After any fix, test these functions:

- [ ] Click "📁 New Folder" - modal should appear
- [ ] Click "📄 New File" - modal should appear  
- [ ] Click "📋 Copy" on a file - modal should appear
- [ ] Click "✂️ Move" on a file - modal should appear
- [ ] Click "🗑️ Delete" on a file - prompt should appear
- [ ] Check a checkbox - batch actions should appear
- [ ] Click "📄 Select Files" - file picker should open
- [ ] Click "📁 Select Folder" - folder picker should open

### Still Not Working?

If you've tried everything above and buttons still don't work:

1. **Take a screenshot** of the browser console (F12 → Console tab)
2. **Note which browser** you're using and version
3. **Note which buttons** specifically don't work
4. **Check if error messages** appear when clicking buttons

### Quick Reference Commands

```bash
# Restart server
sudo pkill -f fileserver.py && cd /jason/script/fileserver && sudo python3 fileserver.py 80 &

# Check if running
ps aux | grep fileserver.py | grep -v grep

# Test server
curl -I http://localhost/

# View in browser
# Then press: Ctrl + Shift + R to force refresh
```

### Browser Cache Locations

If you need to manually clear cache:

**Chrome**:
- Linux: `~/.cache/google-chrome/`
- Windows: `%LocalAppData%\Google\Chrome\User Data\Default\Cache`

**Firefox**:
- Linux: `~/.cache/mozilla/firefox/`
- Windows: `%AppData%\Mozilla\Firefox\Profiles\`

**Edge**:
- Windows: `%LocalAppData%\Microsoft\Edge\User Data\Default\Cache`
