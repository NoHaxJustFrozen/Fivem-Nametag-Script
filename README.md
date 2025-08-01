# 🪪 Dynamic Nametag System for QBCore

An advanced and immersive nametag system for FiveM QBCore servers.  
Supports dynamic display of player names, IDs, and masked identities with recognition memory logic via SQL.

## ⚙️ Features

- 🧑‍🤝‍🧑 Show player nametag only when nearby (configurable range)
- 🎭 Masked players show as **"Maskeli (ID)"**
- 🧠 Recognized players are shown by name (based on SQL memory)
- ❌ `/unut` command to forget a recognized person (removes from both players)
- 🗃️ Persistent memory system using **oxmysql** with player license ID
- 🧾 Supports character-first or license-based memory modes
- 🎯 Fully optimized: 0.00ms idle / 0.01ms active usage

## 🧪 How It Works

- When you're near another player:
  - If they are wearing a mask → `Maskeli (23)`
  - If they are unmasked and not recognized → `Bilinmeyen (23)`
  - If you've recognized them before → `John Doe (23)`
- Memory is saved into SQL and persists across sessions
- `/unut [id]` deletes recognition for both parties using that license ID

## 🛠️ Requirements

- QBCore Framework
- `oxmysql`
- Server using license-based player identification

## ⚙️ Configuration

Everything is adjustable through `config.lua`:
- Visibility range
- DrawText3D styling (black outline included)
- Refresh intervals
- Mask detection logic
- Debug mode toggle

## 🗣️ English Support

Need help configuring or integrating this resource?

> **Discord:** `NoHaxJustFrozen`  

We are happy to help international server owners!

## 📄 License

This project is released under the **MIT License**.

You may freely:
- Use this code in your own server
- Modify and redistribute it
- Sell it (commercial use allowed)

Just keep the original author credit visible in source files.

More info: [https://opensource.org/licenses/MIT](https://opensource.org/licenses/MIT)
