const { spawn } = require('child_process');
const path = require('path');

const backend = path.join(__dirname, 'Nexus-backend');
const frontend = path.join(__dirname, 'Nexus-Frontend');

const commands = [
  { name: 'Reverb', cmd: 'php', args: ['artisan', 'reverb:start', '--host=0.0.0.0', '--port=6001'], cwd: backend, color: '\x1b[34m' },
  { name: 'API', cmd: 'php', args: ['artisan', 'serve', '--host=127.0.0.1', '--port=8000'], cwd: backend, color: '\x1b[31m' },
  { name: 'Queue', cmd: 'php', args: ['artisan', 'queue:work', '--tries=1', '--sleep=3'], cwd: backend, color: '\x1b[35m' },
  { name: 'Vite', cmd: 'npm', args: ['run', 'dev'], cwd: backend, color: '\x1b[33m' },
  { name: 'Frontend', cmd: 'npm', args: ['run', 'dev'], cwd: frontend, color: '\x1b[32m' },
];

console.log('Starting all services...');

commands.forEach(c => {
  const p = spawn(c.cmd, c.args, { cwd: c.cwd, shell: true });
  
  p.stdout.on('data', data => {
      const lines = data.toString().split('\n');
      lines.forEach(line => {
          if (line.trim()) process.stdout.write(`${c.color}[${c.name}]\x1b[0m ${line}\n`);
      });
  });
  
  p.stderr.on('data', data => {
      const lines = data.toString().split('\n');
      lines.forEach(line => {
          if (line.trim()) process.stderr.write(`${c.color}[${c.name}]\x1b[0m ${line}\n`);
      });
  });

  p.on('close', code => {
      console.log(`${c.color}[${c.name}]\x1b[0m Process exited with code ${code}`);
  });
});
