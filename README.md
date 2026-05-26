# Enemy AI Capstone

This is a snapshot of the capstone project my two other group members and I got to work on during our final year of undergrad. This repository consists of the work we accomplished throughout the two semesters alongside some of the papers written for it and the research required for the project.

---

## Table of Contents

- [Overview](#overview)
- [Getting Started](#getting-started)
- [Folder Structure](#folder-structure)
  - [Game](#game-folder)
  - [Proposals](#proposals-folder)
  - [Research](#research-folder)

---

## Overview

This project was focused around different data structures used to control enemy AI and their pathfinding algorithms. Before the project started, I wrote a proposal for the CS faculty and had to do research on enemy AI in game development. Throughout the first semester, the primary focus of the project was to create enemies that use finite state machines and the A* (A-star) algorithm for pathfinding. During the second semester, we created enemies that use behavior trees, incorporated NavMesh into the project, and created a visualization tool to display the enemy AI.

---

## Getting Started

To run this project, you will need Godot 3.6 or a later 3.x version. Godot 4 has not been tested, though it may work. Once you have a compatible version of Godot, import the Game folder and run the project normally (play button in the top right).

---

## Folder Structure

```
Enemy-AI-College-Capstone/
├── Game/
│   └── ...
├── Proposals/
│   └── ...
└── Research/
    └── ...
```

---

### Game Folder

This is the folder that can be imported into Godot 3.6 to run the project. In here are subfolders for player classes, enemies, the visualization tool, and other features. Due to this being the first time every member of our team worked on a game, some of the earlier code and file organization are in need of improvements.

| Subfolder | Description |
|------------------|-------------|
| `ArtAssets/`     | Art assets used for the project. |
| `Components/`     | Projectile and telegraph objects used by the enemies and player. |
| `Entities`     | Enemies and player classes. |
| `GUI/`     | GUI elements for player cooldowns, enemy health, etc. |
| `Scenes/`     | Various menus used by the player including the enemy behavior visualization tool. |
| `Scripts/`     | Scripts for pathfinding and behavior tree scaffolding. |

---

### Proposals Folder

This is a collection of papers written over the course of the project. Initially, I wrote the project proposal outlining the general idea of the project and submitted it to the faculty to try and get this project approved. Once approved, the team I worked with wrote up the proposal for the first semester which went into detail on what we would try to accomplish throughout the semester. By the end of both semesters, we wrote a final report outlining the final state of the project.

---

### Research Folder

This is a collection of research I read over before writing my initial proposal for the project. Out of all the papers, if you could only read a few, I would recommend the Last of Us papers. Those are written by some of the developers who worked on the first game, and they go over how the enemies within the game operate.

---
