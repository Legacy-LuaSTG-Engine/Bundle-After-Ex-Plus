archimedes = {}
Archimedes = archimedes

archimedes.expand = {}

function archimedes.expand:init(center, radius, angle, omiga, deltar)
    self.center = center
    self.radius = radius
    self.angle = angle
    self._omiga = omiga
    self.deltar = deltar
    self.x = self.center.x + self.radius * cos(self.angle)
    self.y = self.center.y + self.radius * sin(self.angle)
end

function archimedes.expand:frame()
    self.radius = self.radius + self.deltar
    self.angle = self.angle + self._omiga
    self.x = self.center.x + self.radius * cos(self.angle)
    self.y = self.center.y + self.radius * sin(self.angle)
end

archimedes.rotation = {}

function archimedes.rotation:init(center, radius, angle, omiga, time)
    self.center = center
    self.radius = 0
    self.angle = angle
    self._omiga = omiga
    self.time = time or 60
    self.deltar = radius / self.time
    self.x = self.center.x + self.radius * cos(self.angle)
    self.y = self.center.y + self.radius * sin(self.angle)
end

function archimedes.rotation:frame()
    if self.timer <= self.time then
        self.radius = self.radius + self.deltar
    end
    self.angle = self.angle + self._omiga
    self.x = self.center.x + self.radius * cos(self.angle)
    self.y = self.center.y + self.radius * sin(self.angle)
end