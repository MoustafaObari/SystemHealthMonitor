<a id="top"></a>

<!-- Banner -->
<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:0078D4,100:FF6F61&height=200&section=header&text=System%20Health%20Monitor%20💻&fontSize=42&fontColor=ffffff&animation=fadeIn&fontAlignY=35&desc=PowerShell%20automation%20for%20system%20diagnostics%2C%20HTML%20reports%2C%20and%20email%20alerts.&descAlignY=55&descAlign=50" alt="System Health Monitor Banner"/>
</p>

<p align="center">
  <a href="https://github.com/MoustafaObari/SystemHealthMonitor">
    <img src="https://img.shields.io/badge/View_on_GitHub-181717?style=for-the-badge&logo=github&logoColor=white" alt="View on GitHub">
  </a>
</p>

<h4 align="center">Turning IT health checks into proactive automation — with PowerShell precision 🧩</h4>

<p align="center">
  <a href="#overview">Overview</a> • 
  <a href="#features">Features</a> • 
  <a href="#tech-stack">Tech Stack</a> • 
  <a href="#getting-started">Setup</a> • 
  <a href="#demo-video">Demo</a> • 
  <a href="#screenshots">Screenshots</a> • 
  <a href="#planned-enhancements">Enhancements</a> • 
  <a href="#developer">Developer</a>
</p>

---

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-0078D4?style=for-the-badge&logo=powershell&logoColor=white">
  <img src="https://img.shields.io/badge/HTML%20Report-FF6F61?style=for-the-badge&logo=html5&logoColor=white">
  <img src="https://img.shields.io/badge/GUI-Windows%20Forms-blue?style=for-the-badge&logo=windows&logoColor=white">
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-1.0.0-brightgreen?style=for-the-badge" alt="Version">
  <img src="https://img.shields.io/github/issues/MoustafaObari/SystemHealthMonitor?color=0078D4&style=for-the-badge" alt="Issues">
</p>

---
<a id="Overview"></a>
## 🧠 Overview  

**Built for IT admins and MSPs to automate system diagnostics and deliver proactive maintenance reports.**

**System Health Monitor** is a professional PowerShell-based automation toolkit that performs deep system diagnostics and generates clean HTML reports — perfect for IT Support, MSPs, and DevOps professionals.

It automatically collects and analyzes:
- CPU utilization  
- Memory usage  
- Disk space and SMART health  
- Windows Update status  
- System uptime  
- Critical event logs  

Reports are saved locally and can be securely sent via email — transforming traditional manual checks into **automated insights**.

---
<a id="Features"></a>
## ✨ Features  

✅ Parallel health checks for multiple endpoints (local & remote via WinRM)  
✅ Interactive **Windows GUI** built with .NET Forms  
✅ Dual **HTML report generation** — Technical (admins) + User-friendly (summary)  
✅ Automated **SMTP email delivery** with attachment logs  
✅ Timestamped **logging and archiving** for every run  
✅ Portable `.exe` packaging for quick use without scripts  

---
<a id="Tech Stack"></a>
## 💻 Tech Stack  

| Layer | Technology |
|-------|-------------|
| **Scripting & Automation** | PowerShell 5+ |
| **Interface** | Windows Forms (.NET) |
| **Reporting** | HTML / CSS |
| **Communication** | SMTP (Email Delivery) |
| **Logging** | File-based (timestamped runs) |
| **Packaging** | PS2EXE for portable deployment |

---
<a id="Getting Started"></a>

## ⚙️ Getting Started  

### 🟦 1️⃣ Clone the Repository  
git clone https://github.com/MoustafaObari/SystemHealthMonitor.git  
cd SystemHealthMonitor  

---

### 🟦 2️⃣ Configure Email Settings  

<details>
<summary>📩 Click to expand email configuration</summary>

Edit the **config.json** file with your SMTP credentials:  

<pre>
{
  "smtpServer": "smtp.gmail.com",
  "smtpPort": 587,
  "smtpUser": "example@gmail.com",
  "smtpPass": "yourpassword",
  "from": "example@gmail.com"
}
</pre>

💡 **Tip:** For Gmail users, enable “App Passwords” for secure SMTP access.

</details>

---

### 🟦 3️⃣ Add Target Computers  

List endpoints to monitor in **computers.txt**:  

localhost  
Server01  
Workstation05  

---

### 🟦 4️⃣ Run the Application  

**Via PowerShell:**  
.\Start-HealthMonitorGUI.ps1  

**Or run the packaged EXE:**  
SystemHealthMonitor.exe  

---

<a id="demo-video"></a>
## 🎥 Demo Video  

📺 Watch a quick walkthrough:  
🎬 [**System Health Monitor Demo**](https://github.com/MoustafaObari/SystemHealthMonitor/blob/main/System%20Health%20Demo.mp4)  

*(or open `System Health Demo.mp4` inside this repository)*

---

<a id="screenshots"></a>
## 🖼️ Screenshots  

| Folder Structure | GUI Launcher | Email Prompt |
|------------------|--------------|---------------|
| ![Screenshot1](Screenshots/1.png) | ![Screenshot2](Screenshots/2.png) | ![Screenshot3](Screenshots/3.png) |

| Running Check | Logs Folder | User-Friendly Report |
|----------------|--------------|-----------------------|
| ![Screenshot4](Screenshots/4.png) | ![Screenshot5](Screenshots/5.png) | ![Screenshot7](Screenshots/7.png) |

| Technical Report (Detailed View) | Generated HTML Reports Summary |
|----------------------------------|--------------------------------|
| ![Screenshot6](Screenshots/6.png) | ![Screenshot8](Screenshots/8.png) |

---

## 📘 Screenshot Descriptions  

| # | Screenshot | Description |
|---|-------------|-------------|
| 1 | Folder structure | Complete project structure with assets |
| 2 | GUI window | Main interface to select and monitor systems |
| 3 | Email dialog | Prompt for recipient & SMTP email configuration |
| 4 | Script execution | PowerShell console running background jobs |
| 5 | Logs folder | Output folder with timestamped reports |
| 6 | Technical report | Full metric view for IT administrators |
| 7 | User-friendly report | Simplified dashboard for end users |
| 8 | Email summary | Confirmation showing generated reports |

---

<a id="planned-enhancements"></a>
## 🧩 Planned Enhancements  

- 📈 Add **CPU and memory trend graphs** in HTML reports  
- 🔍 Integrate **WMI queries** for real-time hardware metrics  
- 💬 Add **Microsoft Teams & Slack** webhook notifications  
- ⏰ Enable **Windows Task Scheduler** for recurring automated scans  
- ☁️ Add **Azure Blob Storage integration** for report backups  

---

<a id="developer"></a>
## 👨‍💻 Developer  

**Moustafa Obari**  
IT Support Specialist • PowerShell Automation • M365/Entra/Intune  
📍 Toronto, Canada 🇨🇦  

🔗 [GitHub](https://github.com/MoustafaObari) | [LinkedIn](https://linkedin.com/in/moustafaobari)  
📧 [moustafaobari@gmail.com](mailto:moustafaobari@gmail.com)

---

<p align="center">
  <img src="https://komarev.com/ghpvc/?username=MoustafaObari&label=Profile%20Views&color=0078D4&style=flat-square" alt="Profile Views Counter"/>
</p>

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:FF6F61,100:0078D4&height=120&section=footer&text=💡%20Turning%20IT%20challenges%20into%20automation%20that%20saves%20time%20and%20improves%20user%20experience.&fontSize=16&fontColor=ffffff&animation=fadeIn" alt="footer banner"/>
</p>

<p align="center">
  © 2025 Moustafa Obari — crafted with 💙 PowerShell, Markdown, and strong coffee.
</p>

<p align="center">
  <a href="#top">⬆ Back to Top</a>
</p>
