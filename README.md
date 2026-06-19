# 🏥 HealthAI Assistant

A privacy-first, RAG-based healthcare chatbot. Runs **100% locally** using Ollama (`gemma2:2b`) — no data ever leaves your device.

Built for: 4GB VRAM laptops | Flutter (Android/iOS/Web) | FastAPI + LangChain + ChromaDB backend.

---

## 🧱 Architecture

```
Flutter App (Android / iOS / Web)
        ↓ HTTP
FastAPI Backend (Python)
        ↓
LangChain RAG Pipeline
        ↓                ↓
   ChromaDB          Ollama (gemma2:2b)
   (vector store)     (local LLM)
        ↑
   TXT / CSV health data files
```

---

## 📂 Project Structure

```
healthcare-ai/
├── backend/              # FastAPI + LangChain + ChromaDB
│   ├── app/
│   │   ├── main.py
│   │   ├── config.py
│   │   ├── routes/chat.py
│   │   ├── rag/loader.py | embedder.py | retriever.py
│   │   └── models/schemas.py
│   ├── data/              # Your TXT/CSV health data
│   ├── requirements.txt
│   └── Dockerfile
│
└── flutter_app/          # Flutter chat UI
    ├── lib/
    │   ├── main.dart
    │   ├── config/app_config.dart
    │   ├── models/message.dart
    │   ├── services/chat_service.dart
    │   ├── screens/chat_screen.dart
    │   └── widgets/
    └── pubspec.yaml
```

---

## 🚀 Quick Start

### 1. Install & run Ollama
```bash
ollama pull gemma2:2b
ollama serve
```

### 2. Backend setup
```bash
cd backend
python -m venv venv
venv\Scripts\activate          # Windows
pip install --upgrade pip wheel setuptools
pip install -r requirements.txt
pip install pydantic-settings langchain-huggingface

uvicorn app.main:app --reload --port 8000
```
Docs: http://localhost:8000/docs

### 3. Load health data (once)
```powershell
Invoke-RestMethod -Method POST -Uri "http://localhost:8000/api/v1/ingest" `
  -ContentType "application/json" -Body '{"force_reload": false}'
```
Or use the app's ⚙️ **Settings → Load Health Data**.

### 4. Run Flutter app
```bash
cd flutter_app
flutter create --platforms=android,ios .   # only needed once
flutter pub get
flutter run -d chrome      # or: -d android / -d ios
```

---

## 🌐 Platform URLs

| Platform | Backend URL |
|---|---|
| Chrome / Web | `http://localhost:8000` |
| Android Emulator | `http://10.0.2.2:8000` |
| iOS Simulator | `http://localhost:8000` |
| Physical device (same WiFi) | `http://<YOUR_PC_IP>:8000` |

URL is auto-detected at runtime in `lib/config/app_config.dart` — no manual switching needed for emulator/simulator/web. For physical devices, update the IP manually.

Find your PC IP:
```bash
ipconfig          # Windows — look for IPv4 Address
```

---

## 🧠 How RAG Works

1. **Ingest** — TXT/CSV files in `data/` are loaded, split into ~500-character chunks
2. **Embed** — Each chunk converted to a vector using `all-MiniLM-L6-v2`
3. **Store** — Vectors saved in ChromaDB (local, on-disk)
4. **Query** — User question embedded → top 3 similar chunks retrieved
5. **Generate** — Chunks + question sent to `gemma2:2b` via Ollama → grounded answer returned

Add more diseases/conditions: drop new `.txt`/`.csv` files into `backend/data/`, then re-ingest with `force_reload: true`.

---

## 🔌 API Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/api/v1/health` | Check Ollama + DB status |
| POST | `/api/v1/ingest` | Load `data/` into ChromaDB |
| POST | `/api/v1/chat` | Send a message, get RAG answer |

---

## ⚕️ Disclaimer

This project is for **educational/informational purposes only**. It is not a medical device and does not provide diagnosis or treatment advice. Always consult a qualified healthcare professional.

---

## 🛠️ Tech Stack

- **LLM:** Ollama — `gemma2:2b` (1.6GB, runs on 4GB VRAM)
- **RAG:** LangChain + ChromaDB
- **Embeddings:** `all-MiniLM-L6-v2` (Sentence Transformers)
- **Backend:** FastAPI (Python)
- **Frontend:** Flutter (Android, iOS, Web)