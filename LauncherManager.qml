pragma Singleton
import QtQuick
import Quickshell

Item {
    id: root

    property bool launcherOpen: false
    property string searchQuery: ""
    property int selectedIndex: 0
    property string selectedCategory: "All"

    readonly property var categoryList: [
        { id: "All", name: "All", icon: "󰌨" },
        { id: "Internet", name: "Internet", icon: "󰖟" },
        { id: "Development", name: "Dev", icon: "" },
        { id: "System", name: "System", icon: "" },
        { id: "Media", name: "Media", icon: "󰝚" },
        { id: "Office", name: "Office", icon: "󰺵" }
    ]

    property var allApps: []
    property var filteredApps: []

    readonly property var currentApp: (filteredApps.length > 0 && selectedIndex >= 0 && selectedIndex < filteredApps.length)
        ? filteredApps[selectedIndex]
        : null

    function toggle(): void {
        if (root.launcherOpen) {
            closeLauncher()
        } else {
            openLauncher()
        }
    }

    function openLauncher(): void {
        root.searchQuery = ""
        root.selectedCategory = "All"
        root.selectedIndex = 0
        root.updateFilter()
        root.launcherOpen = true
    }

    function closeLauncher(): void {
        root.launcherOpen = false
    }

    function setCategory(catId: string): void {
        root.selectedCategory = catId
        root.updateFilter()
    }

    function cycleCategory(forward = true): void {
        let idx = root.categoryList.findIndex(c => c.id === root.selectedCategory)
        if (idx === -1) idx = 0
        if (forward) {
            idx = (idx + 1) % root.categoryList.length
        } else {
            idx = (idx - 1 + root.categoryList.length) % root.categoryList.length
        }
        root.setCategory(root.categoryList[idx].id)
    }

    function categorizeApp(app) {
        let cats = (app.categories || []).map(c => c.toLowerCase())
        if (cats.some(c => c.includes("network") || c.includes("web") || c.includes("internet") || c.includes("browser") || c.includes("chat") || c.includes("messaging"))) {
            return { id: "Internet", name: "Internet", icon: "󰖟" }
        }
        if (cats.some(c => c.includes("development") || c.includes("ide") || c.includes("programming") || c.includes("texteditor") || c.includes("debugger") || c.includes("building"))) {
            return { id: "Development", name: "Development", icon: "" }
        }
        if (cats.some(c => c.includes("audio") || c.includes("video") || c.includes("player") || c.includes("media") || c.includes("graphics") || c.includes("music"))) {
            return { id: "Media", name: "Media", icon: "󰝚" }
        }
        if (cats.some(c => c.includes("office") || c.includes("word") || c.includes("spreadsheet") || c.includes("presentation"))) {
            return { id: "Office", name: "Office", icon: "󰺵" }
        }
        if (cats.some(c => c.includes("system") || c.includes("settings") || c.includes("utility") || c.includes("hardware") || c.includes("terminal") || c.includes("filemanager"))) {
            return { id: "System", name: "System", icon: "" }
        }
        return { id: "System", name: "Utility", icon: "󰀻" }
    }

    function refreshApps(): void {
        let raw = DesktopEntries.applications.values
        let seen = new Set()
        let list = []

        for (let i = 0; i < raw.length; i++) {
            let app = raw[i]
            if (app.noDisplay) continue
            if (!app.name || app.name.trim() === "") continue

            let key = (app.name + "::" + (app.icon || "")).toLowerCase()
            if (seen.has(key)) continue
            seen.add(key)

            let catInfo = categorizeApp(app)

            list.push({
                entry: app,
                id: app.id || "",
                name: app.name,
                genericName: app.genericName || "",
                comment: app.comment || app.genericName || "Application",
                icon: app.icon || "",
                iconPath: Quickshell.iconPath(app.icon, ""),
                categories: app.categories || [],
                category: catInfo.name,
                categoryId: catInfo.id,
                categoryIcon: catInfo.icon,
                runInTerminal: app.runInTerminal || false
            })
        }

        list.sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }))
        root.allApps = list
        root.updateFilter()
    }

    function updateFilter(): void {
        let q = root.searchQuery.trim().toLowerCase()
        let cat = root.selectedCategory

        let filtered = root.allApps.filter(app => {
            if (cat !== "All" && app.categoryId !== cat) return false
            return true
        })

        if (q === "") {
            root.filteredApps = filtered
            root.selectedIndex = 0
            return
        }

        let scored = []
        for (let i = 0; i < filtered.length; i++) {
            let app = filtered[i]
            let name = app.name.toLowerCase()
            let comment = app.comment.toLowerCase()
            let generic = app.genericName.toLowerCase()
            let id = app.id.toLowerCase()

            let score = 0
            if (name === q) {
                score = 100
            } else if (name.startsWith(q)) {
                score = 80
            } else if (name.split(/\s+/).some(w => w.startsWith(q))) {
                score = 65
            } else if (name.includes(q)) {
                score = 50
            } else if (generic.includes(q)) {
                score = 30
            } else if (comment.includes(q)) {
                score = 25
            } else if (id.includes(q)) {
                score = 15
            }

            if (score > 0) {
                scored.push({ app: app, score: score })
            }
        }

        scored.sort((a, b) => {
            if (b.score !== a.score) return b.score - a.score
            return a.app.name.localeCompare(b.app.name)
        })

        root.filteredApps = scored.map(item => item.app)
        root.selectedIndex = 0
    }

    function launchIndex(idx): void {
        if (idx < 0) return

        if (idx < root.filteredApps.length) {
            let item = root.filteredApps[idx]
            launchApp(item)
            return
        }

        if (root.searchQuery.trim().length > 0) {
            launchCommand(root.searchQuery.trim())
        }
    }

    function launchApp(item): void {
        root.closeLauncher()
        try {
            if (item && item.entry) {
                item.entry.execute()
                return
            }
        } catch(e) {
            console.warn("Failed to execute desktop entry directly: " + e)
        }

        if (item && item.id) {
            Quickshell.execDetached(["gtk-launch", item.id])
        }
    }

    function launchTerminal(item): void {
        root.closeLauncher()
        if (!item) return
        if (item.entry && item.entry.command && item.entry.command.length > 0) {
            let cmdStr = item.entry.command.join(" ")
            Quickshell.execDetached(["kitty", "-e", "sh", "-c", cmdStr])
        } else if (item.id) {
            Quickshell.execDetached(["kitty", "-e", "gtk-launch", item.id])
        }
    }

    function launchCommand(cmd): void {
        root.closeLauncher()
        if (!cmd || cmd.trim() === "") return
        Quickshell.execDetached(["sh", "-c", cmd])
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            root.refreshApps()
        }
    }

    Component.onCompleted: {
        root.refreshApps()
    }
}
