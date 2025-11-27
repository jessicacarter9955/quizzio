# Guide: Push the app and get APKs

This guide assumes **you are not a developer**. Follow the steps as written.

---

## 1. What are Git, GitHub and Actions?

- **Git**: a history of your project. It remembers every change.
- **GitHub**: an online backup of your Git project.
- **GitHub Actions**: small robots that run in the cloud when you push code. Here we use it to **build APK files for you**.

---

## 2. How to push your latest changes

Do this every time you want GitHub to build a new APK.

1. Open **PowerShell**.
2. Go to the project folder:
   ```powershell
   cd "C:\Users\jessi\Downloads\QuizVocab2"
   ```
3. See what changed (optional):
   ```powershell
   git status
   ```
4. Add all changes:
   ```powershell
   git add .
   ```
5. Save them with a short message:
   ```powershell
   git commit -m "Update app"
   ```
6. Send them to GitHub:
   ```powershell
   git push
   ```

After `git push`, GitHub will automatically start the build robots (Actions).

---

## 3. Get the **debug APK** from GitHub

A **debug APK** is good for testing on your own phone.

1. After you `git push`, open your repo:
   - <https://github.com/dvd2pe/quizVocab>
2. Click the **"Actions"** tab at the top.
3. Click the latest run called **"Build debug APK"** (or similar name).
4. Scroll to the bottom, find **Artifacts**.
5. Download **`app-debug-apk`** (it is a ZIP file).
6. Open the ZIP and get `app-debug.apk`.
7. Copy `app-debug.apk` to your Android phone and install it.

You can also open this from the **GitHub mobile app**:
- Open the repo → **Actions** → pick latest run → **View in browser** if needed → download the artifact.

---

## 4. Get a **release APK** (for real users)

A **release APK** is the version you would upload to stores or give to users.

Right now, the project is set up to build **debug** APKs in GitHub. For a full **release** APK you have two options:

### Option A – Build release APK on your computer

1. Open **PowerShell**.
2. Go to the project folder:
   ```powershell
   cd "C:\Users\jessi\Downloads\QuizVocab2"
   ```
3. Run:
   ```powershell
   flutter pub get
   flutter build apk --release
   ```
4. When it finishes, the file is here:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```
5. Copy `app-release.apk` to your phone or upload it where you need.

### Option B – (Future) Release APK from GitHub

If you want, we can extend the GitHub Action so it also builds a **release** APK and uploads it as another artifact (for example `app-release-apk`). Then the download steps would be the same as for the debug APK.

---

## 5. What you asked for (in simple words)

You asked to:

- "Create a GitHub Actions file to build a **debug APK** every time I push to GitHub, so I can download it from the GitHub app."

That is now done:

- When you run the Git commands above (`git add`, `git commit`, `git push`), GitHub automatically:
  - builds a **debug APK** for this project, and
  - offers it as a **downloadable file (artifact)** on the Actions page.

So your workflow is:

1. Change the app code.
2. Run 4 commands: `git add .`, `git commit -m "..."`, `git push`.
3. Wait for the GitHub Action to finish.
4. Download the **debug APK** from the Actions page.
